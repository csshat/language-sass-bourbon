_ = require 'lodash'
{css, utils} = require 'octopus-helpers'


_declaration = ($$, scssSyntax, property, value, modifier) ->
  return unless value?

  if scssSyntax
    semicolon = ';'
  else
    semicolon = ''

  if modifier
    value = modifier(value)

  $$ "#{property}: #{value}#{semicolon}"


_mixin = ($$, name, value, modifier) ->
  return unless value?

  if modifier
    value = modifier(value)

  $$ "@include #{name}(#{value});"


renderColor = (color, colorVariable) ->
  colorVariable = renderVariable(colorVariable)
  if color.a < 1
    "rgba(#{colorVariable}, #{color.a})"
  else
    colorVariable


_comment = ($, showTextSnippet, text) ->
  return unless showTextSnippet
  $ "// #{text}"

_convertColor = _.partial(css.convertColor, renderColor)


defineVariable = (name, value, options) ->
  semicolon = if options.scssSyntax then ';' else ''
  "$#{name}: #{value}#{semicolon}"


renderVariable = (name) -> "$#{name}"


_startSelector = ($, selector, scssSyntax, selectorOptions, text) ->
  return unless selector
  curlyBracket = if scssSyntax then ' {' else ''
  $ '%s%s', utils.prettySelectors(text, selectorOptions), curlyBracket


_endSelector = ($, selector, scssSyntax) ->
  $ '}' if selector and scssSyntax


class Stylus

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $.indents, @options.scssSyntax)
    mixin = _.partial(_mixin, $.indents)
    comment = _.partial(_comment, $, @options.showTextSnippet)
    unit = _.partial(css.unit, @options.unit)
    convertColor = _.partial(_convertColor, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, @options.quoteType)

    selectorOptions =
      separator: @options.selectorTextStyle
      selector: @options.selectorType
      maxWords: 3
    startSelector = _.partial(_startSelector, $, @options.selector, @options.scssSyntax, selectorOptions)
    endSelector = _.partial(_endSelector, $, @options.selector, @options.scssSyntax)

    if @type == 'textLayer'
      for textStyle in css.prepareTextStyles(@options.inheritFontStyles, @baseTextStyle, @textStyles)
        comment(css.textSnippet(@text, textStyle))

        if @options.selector
          if textStyle.ranges
            selectorText = utils.textFromRange(@text, textStyle.ranges[0])
          else
            selectorText = @name

          startSelector(selectorText)

        if not @options.inheritFontStyles or textStyle.base
          if @options.showAbsolutePositions
            declaration('position', 'absolute')
            declaration('left', @bounds.left, unit)
            declaration('top', @bounds.top, unit)

          declaration('opacity', @opacity)
          if @shadows
            declaration('text-shadow', css.convertTextShadows(convertColor, unit, @shadows))

        fontStyles(textStyle)

        endSelector()
        $.newline()
    else
      comment("Style for #{utils.trim(@name)}")
      startSelector(@name)

      if @options.showAbsolutePositions
        declaration('position', 'absolute')
        declaration('left', @bounds.left, unit)
        declaration('top', @bounds.top, unit)

      if @bounds
        if @bounds.width == @bounds.height
          mixin('size', @bounds.width, unit)
        else
          mixin('size', "#{unit(@bounds.width)} #{unit(@bounds.height)}")

      declaration('opacity', @opacity)

      if @background
        declaration('background-color', @background.color, convertColor)

        if @background.gradient
          gradientStr = css.convertGradients(convertColor, @background.gradient)
          mixin('background-image', gradientStr) if gradientStr

      if @borders
        border = @borders[0]
        declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

      declaration('border-radius', @radius, css.radius)

      if @shadows
        declaration('box-shadow', css.convertShadows(convertColor, unit, @shadows))

      endSelector()


module.exports = {defineVariable, renderVariable, renderClass: Stylus}
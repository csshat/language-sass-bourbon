_ = require 'lodash'
{css, utils} = require 'octopus-helpers'
sass = require 'octopus-sass'


setNumberValue = (number) ->
  converted = parseInt(number, 10)
  if not number.match(/^\d+(\.\d+)?$/)
    return 'Please enter numeric value'
  else
    return converted


class Sass

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(sass.declaration, $.indents, @options.scssSyntax)
    mixin = _.partial(sass.mixin, $.indents, @options.scssSyntax)
    comment = _.partial(sass.comment, $, @options.showComments)

    rootValue = switch @options.unit
      when 'px' then 0
      when 'em' then @options.emValue
      when 'rem' then @options.remValue
    unit = _.partial(css.unit, @options.unit, rootValue)

    convertColor = _.partial(sass.convertColor, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, @options.quoteType)

    selectorOptions =
      separator: @options.selectorTextStyle
      selector: @options.selectorType
      maxWords: 3
      fallbackSelectorPrefix: 'layer'
    startSelector = _.partial(sass.startSelector, $, @options.selector, @options.scssSyntax, selectorOptions)
    endSelector = _.partial(sass.endSelector, $, @options.selector, @options.scssSyntax)

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
          gradientStr = css.convertGradients(convertColor, {gradient: @background.gradient, @bounds})
          mixin('background-image', gradientStr) if gradientStr

      if @borders
        border = @borders[0]
        declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

      declaration('border-radius', @radius, css.radius)

      if @shadows
        declaration('box-shadow', css.convertShadows(convertColor, unit, @shadows))

      endSelector()


module.exports =
  defineVariable: sass.defineVariable
  renderVariable: sass.renderVariable
  setNumberValue: setNumberValue
  renderClass: Sass

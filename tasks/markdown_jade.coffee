#
# grunt-markdown-jade
# https://github.com/realyze/grunt-markdown-jade
#
# Copyright (c) 2013 Tomas Brambora
# Licensed under the MIT license.
#

'use strict'

module.exports = (grunt) ->

  {markdown} = require('markdown')
  _ = require 'underscore'
  _s = require 'underscore.string'
  _.mixin(_s.exports())

  defaults = {
    wrap:
      h1: 'section'
      h2: 'article'
  }

  @options = _.extend defaults, @options

  processFile = (f) =>
    text = grunt.file.read f
    tree = markdown.parse text

    html = markdown.toHTMLTree tree
    console.log html
    console.log '-----'

    tags = _.keys(@options.wrap).reverse()

    for tag in tags
      elemRows = _.filter html, _.isArray
      tagRows = _.filter elemRows, (row) -> row[0] == tag

      while not _.isEmpty(tagRows)
        tagRow = tagRows.shift()

        index = _.indexOf html, tagRow

        if not _.isEmpty(tagRows)
          end = _.indexOf(html, tagRows[0]) - index
        else
          end = html.length - index

        console.log 'tag', index, end

        tagTree = html.splice(index, end)

        headerId = _(tagRow).chain()
          .last()
          .slugify()
          .value()
          .toLowerCase()

        tagTree = _.union(@options.wrap[tag], {id: headerId}, tagTree)

        console.log 'tree', tagTree

        html.splice index, 0, tagTree


    console.log html


    console.log '========='
    console.log markdown.renderJsonML html

  # Please see the Grunt documentation for more information regarding task
  # creation: http://gruntjs.com/creating-tasks

  grunt.registerMultiTask 'markdown_jade', 'The best Grunt plugin ever.', ->
    _.each @files, (f) ->
      files = _.filter f.src, (filepath) ->
        console.log filepath
        if not grunt.file.exists filepath
          grunt.log.warn "Source file #{filepath} not found."
          return false
        return true
      console.log files

      (processFile(f) for f in files)



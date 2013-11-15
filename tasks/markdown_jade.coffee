#
# grunt-markdown-jade
# https://github.com/realyze/grunt-markdown-jade
#
# Copyright (c) 2013 Tomas Brambora
# Licensed under the MIT license.
#

'use strict'

module.exports = (grunt) ->

  # What elements we're looking for.
  TAGS = ['h1', 'h2', 'h3', 'h4']

  {markdown} = require('markdown')
  _ = require 'underscore'
  _s = require 'underscore.string'
  _.mixin(_s.exports())
  path = require 'path'


  compare = (tag1, tag2) ->
    if _.indexOf(TAGS, tag1) > _.indexOf(TAGS, tag2)
      return -1
    if _.indexOf(TAGS, tag1) == _.indexOf(TAGS, tag2)
      return 0
    return 1


  insert = (data, root, opts) ->
    tag = data[0][0]

    if not root.children.length
      console.log 'no children'
      headerId = getHeaderId data, opts
      root.children.push
        id: headerId
        body: markdown.renderJsonML _.union(['html'], data)
        children: []
        tag: tag
      return root

    if compare(tag, _.last(_.pluck(root.children, 'tag'))) >= 0
      console.log 'last child'
      root.children.push
        id: headerId
        body: markdown.renderJsonML _.union(['html'], data)
        children: []
        tag: tag
      return root

    console.log 'recursing...'
    insert(data, _.last(root.children), opts)
    return root


  processFile = (f, opts) ->
    # Read'n'parse the md file.
    text = grunt.file.read f
    html = markdown.toHTMLTree markdown.parse text

    # Gimme all the headers in JsonML.
    elemRows = _.filter html, _.isArray
    tagRows = _.filter elemRows, (row) -> row[0] in TAGS

    data = []

    # Parse the JsonML tree to get the "HTML regions" that correspond to each
    # header (basically, this splits the tree with 'h?' as separators).
    while not _.isEmpty(tagRows)
      tagRow = tagRows.shift()
      index = _.indexOf html, tagRow

      if not _.isEmpty(tagRows)
        end = _.indexOf(html, tagRows[0])
      else
        end = html.length

      tagTree = html.slice(index, end)

      data.push tagTree


    # Compile data objects per region (we'll pass those objects to the
    # template later on).
    res = {}
    root = {children: []}

    for d in data
      root = insert d, root, opts
      console.log 'root after', root
      console.log '========'

    console.log JSON.stringify root, null, 2
    ###
      tag = d[0][0]
      res[tag] or= []

      headerId = getHeaderId d, opts

      res.push
        "#{tag}":
          id: headerId
          body: markdown.renderJsonML _.union(['html'], d)
          parent: parent

      if _.indexOf(TAGS, tag) > _.indexOf(TAGS, parent)
        parent = tag
    ###

    return res


  # Returns header id for a region (accessible in the template).
  # Either you can specify the id in the Markdown file or it will take the
  # heading text and slugify it.
  getHeaderId = (data, opts) ->
    text = _.last data[0]
    match = text.match opts.id_pattern

    if match
      # Strip the ID pattern.
      data[0][data[0].length - 1] = _.trim text.replace(opts.id_pattern, '')
      headerId = match[1]

    headerId or= _(data[0]).chain().last().slugify().value().toLowerCase()
    return headerId


  grunt.registerMultiTask 'markdown_jade', 'The best Grunt plugin ever.', ->

    options = this.options
      id_pattern: /{(.+)}/

    _.each @files, (f) =>

      files = _.filter f.src, (filepath) ->
        if not grunt.file.exists filepath
          grunt.log.warn "Source file #{filepath} not found."
          return false
        return true

      parsedFilesData = _.map files, (file) -> [file, processFile(file, options)]

      _.each parsedFilesData, ([filepath, data]) ->

        basename = path.basename filepath, path.extname(filepath)
        tpl = f.template or options.template

        grunt.file.copy tpl, "#{f.dest}/#{basename}.html",
          process: (contents, path) ->
            grunt.template.process contents, data: data

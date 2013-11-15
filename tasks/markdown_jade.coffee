#
# grunt-markdown-jade
# https://github.com/realyze/grunt-markdown-jade
#
# Copyright (c) 2013 Tomas Brambora
# Licensed under the MIT license.
#
# So, what we'll feed into the template when we get it all parsed and whatnot
# is something akin to:
#
# {
#   "children": [
#     {
#       "id": "foobar",
#       "body": "<h1>Solutions</h1>\n<p>This is the Solutions noodle.</p>",
#       "children": [
#         {
#           "id": "overview",
#           "body": "<h2>Overview</h2>\n<p>This is the overview of the Solutions noodle.</p>",
#           "children": [],
#           "tag": "h2"
#         },
#         {
#           "id": "web-apps",
#           "body": "<h2>Web Apps</h2>\n<p>This is my rant about Web Apps</p>,
#           "children": [],
#           "tag": "h2"
#         },
#         {
#           "id": "mobile-apps",
#           "body": "<h2>Mobile apps</h2>\n\n<p>Another rant</p>",
#           "children": [],
#           "tag": "h2"
#         }
#       ],
#       "tag": "h1"
#     }
#   ]
# }
#

'use strict'

module.exports = (grunt) ->

  {markdown} = require('markdown')
  _ = require 'underscore'
  _s = require 'underscore.string'
  _.mixin(_s.exports())
  path = require 'path'
  beautifyHTML = require('js-beautify').html


  # Global options hash.
  _options = {}


  # Returns -1 if tag1 is less important than tag2, 0 if they're the same
  # and +1 if tag2 is more important.
  # The importance is based on the `options.tags` array.
  compare = (tag1, tag2) ->
    if _.indexOf(_options.tags, tag1) > _.indexOf(_options.tags, tag2)
      return -1
    if _.indexOf(_options.tags, tag1) == _.indexOf(_options.tags, tag2)
      return 0
    return 1


  # Inserts a DOM region into the DOM region tree.
  insert = (data, root) ->
    tag = data[0][0]

    headerId = getHeaderId data

    if not root.children.length
      root.children.push
        id: headerId
        body: markdown.renderJsonML _.union(['html'], data)
        children: []
        tag: tag
      return root

    if compare(tag, _.last(_.pluck(root.children, 'tag'))) >= 0
      root.children.push
        id: headerId
        body: markdown.renderJsonML _.union(['html'], data)
        children: []
        tag: tag
      return root

    insert(data, _.last(root.children))

    return root


  processFile = (f) ->
    # Read'n'parse the md file.
    text = grunt.file.read f
    html = markdown.toHTMLTree markdown.parse text

    # Find all the relevant elements (i.e., headers) in JsonML.
    elemRows = _.filter html, _.isArray
    tagRows = _.filter elemRows, (row) -> row[0] in _options.tags

    # Parse the JsonML tree to get the "HTML regions" that correspond to each
    # header. Simply put, this splits the tree using 'h?' as separators).
    #
    # The idea here is that each header starts a new region and we want an
    # id for that region and the text before the next region starts. We'll
    # feed this info into the template and get a nice HTML partial.
    data = []
    while not _.isEmpty(tagRows)
      tagRow = tagRows.shift()
      index = _.indexOf html, tagRow

      if not _.isEmpty(tagRows)
        end = _.indexOf(html, tagRows[0])
      else
        end = html.length

      tagTree = html.slice(index, end)

      data.push tagTree


    res = {}
    root = {children: []}

    # Create the DOM region tree (we'll pass this tree to the
    # template later on).
    for d in data
      insert d, root

    grunt.log.debug JSON.stringify root, null, 2

    return root


  # Returns header id for a region (accessible in the template).
  # Either you can specify the id in the Markdown file or it will take the
  # heading text and slugify it.
  getHeaderId = (data) ->
    text = _.last data[0]
    match = text.match _options.id_pattern

    if match
      # Strip the ID pattern.
      data[0][data[0].length - 1] = _.trim text.replace(_options.id_pattern, '')
      headerId = match[1]

    # Slugify the header text.
    headerId or= _(data[0]).chain().last().slugify().value().toLowerCase()

    return headerId


  grunt.registerMultiTask 'markdown_jade', 'The best Grunt plugin ever.', ->

    # Default options.
    _options = @options
      id_pattern: /{(.+)}/
      tags: ['h1', 'h2', 'h3']

    _.each @files, (f) =>

      files = _.filter f.src, (filepath) ->
        if not grunt.file.exists filepath
          grunt.log.warn "Source file #{filepath} not found."
          return false
        return true

      # Parse the Markdown files specified in the currently processed
      # file dict.
      parsedFilesTuples = _.map files, (file) -> [file, processFile(file)]

      # Expand the specified template for each parsed file (with the data
      # compiled from the md file).
      _.each parsedFilesTuples, ([filepath, data]) ->

        basename = path.basename filepath, path.extname(filepath)
        tpl = f.template or _options.template

        grunt.file.copy tpl, "#{f.dest}/#{basename}.html",
          process: (contents, path) ->
            html = grunt.template.process contents, data: data
            # Pretty print the html
            if _options.pretty
              beautifyHTML html
            else
              html

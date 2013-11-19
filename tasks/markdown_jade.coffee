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

  _ = require 'underscore'
  _s = require 'underscore.string'
  _.mixin(_s.exports())

  {markdown} = require('markdown')
  beautifyHTML = require('js-beautify').html
  Entities = require('html-entities').AllHtmlEntities
  {decode} = new Entities()


  # Global options hash.
  _options = {}


  # Returns -1 if tag1 is less important than tag2, 0 if they're the same
  # and +1 if tag2 is more important.
  # The importance is based on the `options.tags` array.
  compareTags = (tag1, tag2) ->
    tagIndex = _.partial _.indexOf, _options.tags
    if tagIndex(tag1) > (tagIndex tag2)
      return -1
    if tagIndex(tag1) == (tagIndex tag2)
      return 0
    return 1


  # Inserts a DOM region into the DOM region tree.
  insert = (data, root) ->
    tag = data[0][0]

    headerId = getHeaderId data
    childTag = _.last _.pluck root.children, 'tag'

    if _.isEmpty(root.children) or compareTags(tag, childTag) >= 0
      # Note: The stringify/parse dance is necessary because renderJsonML is
      # changing data object.
      getHTML = (data) -> _.union(['html'], JSON.parse JSON.stringify data)

      root.children.push
        id: headerId
        content: markdown.renderJsonML(getHTML data)
        header: markdown.renderJsonML(getHTML [data[0]])
        body: markdown.renderJsonML(getHTML _.rest(data))
        children: []
        tag: tag

      if _options.decode
        # Make sure we decode the HTML entities.
        for attr in ['content', 'header', 'body']
          _.last(root.children)[attr] = decode _.last(root.children)[attr]
      return root

    return insert(data, _.last(root.children))


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
    data = _.map tagRows, (tagRow, pos) ->
      index = _.indexOf html, tagRow
      next = tagRows[pos + 1]
      regionEnd = if next? then _.indexOf(html, next) else html.length
      return html.slice index, regionEnd

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
    {id_pattern} = _options
    match = text.match id_pattern

    if match
      # Strip the ID pattern.
      data[0][data[0].length - 1] = _.trim text.replace(id_pattern, '')
      headerId = match[1]

    # Slugify the header text.
    headerId or= _(data[0]).chain().last().slugify().value().toLowerCase()

    return headerId


  grunt.registerMultiTask 'markdown_jade', 'The best Grunt plugin ever.', ->

    # Default options.
    _options = @options
      id_pattern: /{(.+)}/
      tags: ['h1', 'h2', 'h3']

    _.each @files, ({src, template, dest}) =>

      files = _.filter src, (filepath) ->
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
        tpl = template or _options.template

        grunt.file.copy tpl, dest,
          process: (contents, path) ->
            html = grunt.template.process contents, data: data
            # Pretty print the html.
            return if _options.pretty then beautifyHTML(html) else html

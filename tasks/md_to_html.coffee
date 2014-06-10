#
# grunt-md-templator
# https://github.com/realyze/grunt-md-templator
#
# Copyright (c) 2013 Tomas Brambora
# Licensed under the MIT license.
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
  path = require 'path'
  mkdirp = require 'mkdirp'


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

  isBlockTag = (tag) -> tag.indexOf('block') == 0

  getBlockName = (data) -> data[0][1].replace(/---\s*([^-\s]+)\s*---/, '$1')

  # Inserts a DOM region into the DOM region tree.
  insert = (data, root) ->
    tag = data[0][0]
    childTag = _.last _.pluck root.children, 'tag'

    # Handle blocks. Every block "inherits" heading level from 
    # its parent header. Block ends when we either find a new block
    # tag or when the parent heading section ends.
    if isBlockTag(tag)
      if not root.tag?
        # It's the very first level of the tree, so just recurse in.
        return insert(data, _.last(root.children))

      if childTag? and isBlockTag(childTag)
        # Current tag is a block and the last delimiter was a block =>
        # end the previous block and start a new sibling block (with the
        # same heading level).
        tag = data[0][0] = childTag

      if _.isEmpty(root.children)
        # We've just found a new block without predecesors => start
        # a new block with parent heading level.
        tag = data[0][0] = "block-#{root.tag}"

    if _.isEmpty(root.children) or compareTags(tag, childTag) >= 0
      # Note: The stringify/parse dance is necessary because renderJsonML is
      # changing data object.
      getHTML = (data) -> _.union(['html'], JSON.parse JSON.stringify data)

      metadata = getMetadata data

      root.children.push
        id: metadata.id
        metadata: metadata
        content: markdown.renderJsonML(getHTML data)
        header: markdown.renderJsonML(getHTML [data[0]])
        body: markdown.renderJsonML(getHTML _.rest(data))
        children: []
        tag: tag
        isBlock: isBlockTag(tag)
        name: if isBlockTag(tag) then getBlockName(data) else null

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

    findDelimiter = (row) ->
      row[0] in _options.tags or (typeof(row[1]) is 'string' and row[1].match(/^---[^-]+---$/))


    # Find all the relevant elements (i.e., headers) in JsonML.
    elemRows = _.filter html, _.isArray
    tagRows = _.filter elemRows, findDelimiter

    tagRows = _.map tagRows, (row) ->
      if typeof(row[1]) is 'string' and row[1].match(/^---[^-]+---$/)
        row[0] = 'block'
      return row
    
    blockTags = ("block-#{tag}" for tag in _options.tags)
    # ## Trick:
    # For every tag that creates scope, create it's block element child and
    # give one less priority level.
    # We use this to compare tag priorities (so that a block nested withing
    # an e.g. `h2` scope will have lower priority than `h2` but bigger than `h3`).
    _options.tags = _.flatten _.zip _options.tags, blockTags

    # ## Trick:
    # Add level-yet-to-be-determined block to the end of _options.tags (i.e., give
    # it the least priority).
    # That way it will always have a lower priority than any non-block tag we
    # find and hence will become it's child.
    _options.tags.push 'block'

    grunt.log.debug 'tagRows', tagRows
    grunt.log.debug '_options.tags', _options.tags

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

    root = findChildBlocks(root)
    root = findHTMLSubtrees(root)

    grunt.log.debug JSON.stringify root, null, 2

    return root


  # DFS the tree and assign a `blocks` hash property to each node. The property
  # contains child nodes which are blocks. This is mainly for convenience so
  # that users can access the block by `node.blocks.<myBlockName>` shortcut.
  findChildBlocks = (root) ->
    root.blocks = {}
    for child in root.children
      findChildBlocks(child)
      if child.isBlock
        root.blocks[child.name] = child
    return root


  # DFS the tree and assign `html` property to each node. The property contains
  # the HTML content of the subtree (kind of like jQuery's `html()` method).
  findHTMLSubtrees = (root) ->
    for child in root.children
      findHTMLSubtrees(child)

    if root.children.length > 0
      childHTML = _.pluck(root.children, 'html').join('')
    else
      childHTML = ""
    
    if root.isBlock
      root.html = (root.body or '') + childHTML
    else
      root.html = (root.content or '') + childHTML

    root.html = _.trim(root.html)
    return root


  # Returns metadata for a region (accessible in the template).
  getMetadata = (data) ->
    grunt.log.debug 'data', data

    text = _.last data[0]
    {metadata_pattern} = _options
    match = text.match metadata_pattern

    metadata = {}

    if match
      # Strip the metadata pattern.
      data[0][data[0].length - 1] = _.trim text.replace(metadata_pattern, '')
      metadata = JSON.parse match[1]

    metadata.id or= _(data[0]).chain().last().slugify().value().toLowerCase()

    grunt.log.debug 'metadata', metadata

    return metadata


  grunt.registerMultiTask 'md_to_html', 'Turn markdown & template into HTML.', ->

    # Default options.
    _options = @options
      metadata_pattern: /{(.+)}/
      tags: ['h1', 'h2', 'h3']

    _.each @files, ({src, template, dest, ext}) =>

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

        if not _options.multiple_files
          grunt.file.copy tpl, dest,
            process: (contents, path) ->
              html = grunt.template.process contents, data: _.extend(data, _options.data)
              # Pretty print the html.
              return if _options.pretty then beautifyHTML(html) else html
        else
          splitIntoMultipleFiles(data, tpl, dest, ext)


  getDataLeaves = (data, pathToRoot=[], res) ->
    for child in data.children
      #parent = if data.id then [data.id] else []
      getDataLeaves(child, _.union(pathToRoot, [data]), res)

    # Don't forget the leave node.
    pathToRoot.push(data)

    # We're only interested in the leaves.
    return unless _.isEmpty(data.children)

    # Forget the first part (that's the "header").
    res.push _.rest(pathToRoot)


  splitIntoMultipleFiles = (data, tpl, dest, ext) ->
    leaves = []
    getDataLeaves data, [], leaves

    tmp = []

    # Add the non-leaf paths to the mix as well (so that we have links to
    # e.g. foo/bar, i.e., the "section overview page").
    leaves = _.union leaves, (_.initial(p) for p in leaves)

    for leavePath in leaves when leavePath.length > 0
      parts = _.union([dest], _.pluck(leavePath, 'id'))
      leaveDest = path.join.apply @, parts
      leaveDest = "#{leaveDest}#{ext}"

      grunt.log.debug 'mkdirp', path.dirname(leaveDest)
      grunt.log.debug 'section',_.pluck(leavePath, 'id'), _.last(leavePath)

      if not _.last(leavePath).body
        grunt.log.debug "skipping ", _.pluck(leavePath, 'id'), ": no body"
        continue

      mkdirp.sync path.dirname(leaveDest)

      grunt.file.copy tpl, leaveDest,
        process: (contents, path) ->
          html = grunt.template.process contents, data: _.extend({
              section: _.last(leavePath)
              ids: _.pluck(leavePath, 'id')
              all: data
              root: leavePath[0]
            }, _options.data)
          # Pretty print the html.
          return if _options.pretty then beautifyHTML(html) else html

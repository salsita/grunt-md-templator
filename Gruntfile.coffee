#
# * grunt-markdown-jade
# * https://github.com/realyze/grunt-markdown-jade
# *
# * Copyright (c) 2013 Tomas Brambora
# * Licensed under the MIT license.
#
"use strict"
module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    jshint:
      all: ["Gruntfile.js", "tasks/*.js", "<%= nodeunit.tests %>"]
      options:
        jshintrc: ".jshintrc"


    # Before generating any new files, remove any previously-created files.
    clean:
      tests: ["tmp"]


    # Configuration to be run (and then tested).
    markdown_jade:
      "2-levels":
        options:
          template: "test/fixtures/noodle2.html.tpl"
          id_pattern: /{(.+)}/
          tags: ['h1', 'h2', 'h3']
          pretty: true

        files: [
          {
            src: ["test/fixtures/test*.md"]
            template: "test/fixtures/noodle.html.tpl"
            dest: "tmp"
            cwd: '.'
            expand: true
            ext: '.html'
          }
        ]

      "3-levels":
        options:
          template: "test/fixtures/3-levels.html.tpl"
          id_pattern: /{(.+)}/
          tags: ['h1', 'h2', 'h3']
          pretty: true

        files: [
          {
            src: ["test/fixtures/3-levels.md"]
            dest: "tmp"
            cwd: '.'
            expand: true
            ext: '.html'
          }
        ]

    # Unit tests.
    nodeunit:
      tests: ["test/*_test.js"]


  # Actually load this plugin's task(s).
  grunt.loadTasks "tasks"

  # These plugins provide necessary tasks.
  grunt.loadNpmTasks "grunt-contrib-jshint"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-nodeunit"

  # Whenever the "test" task is run, first clean the "tmp" dir, then run this
  # plugin's task(s), then test the result.
  grunt.registerTask "test", ["clean", "markdown_jade", "nodeunit"]

  # By default, lint and run all tests.
  grunt.registerTask "default", ["jshint", "test"]

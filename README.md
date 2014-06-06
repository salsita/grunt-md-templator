# grunt-markdown-processor

1. Write a Markdown file with your content.
2. Write a lo-dash (Grunt) template that describes the resulting HTML.
3. Let this plugin generate the HTML files for you.

<!--a href="https://nodei.co/npm/restq/"><img src="https://nodei.co/npm/restq.png"></a-->

[![Build Status](https://secure.travis-ci.org/realyze/grunt-md-templator.png)](http://travis-ci.org/realyze/grunt-md-templator)

### What is that good for?
Consider you have a number of similar pages you want to author content for. And you
prefer writing them in Markdown and/or you're not an HTML person.

We got you covered.

Take this plugin and let some HTML savvy gal or guy write the code for you.
Then run it through this plugin and it will generate tasty fresh HTML for ya!

## Getting Started
This plugin requires Grunt `~0.4.1`

If you haven't used [Grunt](http://gruntjs.com/) before, be sure to check out the [Getting Started](http://gruntjs.com/getting-started) guide, as it explains how to create a [Gruntfile](http://gruntjs.com/sample-gruntfile) as well as install and use Grunt plugins. Once you're familiar with that process, you may install this plugin with this command:

```shell
npm install grunt-md-templator --save-dev
```

Once the plugin has been installed, it may be enabled inside your Gruntfile with this line of JavaScript:

```js
grunt.loadNpmTasks('grunt-md-templator');
```

## The "grunt-md-templator" task
Run this task with the `grunt md_to_html` command.

Task targets, files and options may be specified according to the Grunt Configuring tasks guide.


### Overview

In your project's Gruntfile, add a section named `md_to_html` to the data object passed into `grunt.initConfig()`.

### Options

#### template
Type: `String`

Path to the Grunt (Lo-Dash) template that will be usd to generate the HTML files.

#### id\_pattern
Type: `RegExp`
Default: `/{(.+)}/`

If you want your markdown sections to have a different id than that derived
from the section title (by default the id will be the section title in lower
case joined by '-') you can specify what regexp will the plugin look for. For
example the default value will strip anything between curly braces and use that
as the id.

#### tags
Type: `Array of Strings`
Default: `['h1', 'h2', 'h3']`

What sections do we want to look for when parsing. If not included here the
resulting JS object will not contain the missing sections. By default anything
less important than `h3` will be contained within it's `h3` parent.

#### pretty
Type: `Boolean`
Default: `false`

Set to true if the resulting HTML should be pretty-printed.


## Block support
Version `0.2.0` comes with experimental block support.

You can start a block by inserting a line like `--- blockName ---` preceded and
followed by an empty line. Block ends when its parent section ends or when another
block is found (see the [test/fixtures/blocks.md](test case) for an example).

Blocks can be accessed via `<section>.blocks` attribute which is a hash containing data for block nodes (again, see the test for an example).


## Accessing markdown data in the HTML template
Each "section" has the following data:

* `id` - the header id
* `metadata` - a hash containing whatever is in `{}` at the end of the header
  line (e.g. `## foo {{"bar": 42}}` => `section.metadata == {bar: 42}`
* `body` - the HTML of the body of the section (please note that this *does not*
  include the HTML of the subsections)
* `header` - the HTML of the header of the section
* `content` -  concatenated `header` and `body`
* `html` - sort of like jQuery's `html()` method; HTMLof the whole subtree (not
  including this section header).
* `blocks` - a has containing child blocks data for this section
* `children` - an array of child nodes for this section (including blocks)
* `name` - the name of the block if section is a block, `null` otherwise


## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History
 * 2013-12-27   v0.1.0   Initial release.

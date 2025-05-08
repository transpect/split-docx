# split-docx
this module helps with splitting docx files. It is just a library. To run it standalone, you need to make it part of a transpect project, see below.

* The main pipeline supports splitting on part and chapter headings. Their styles can be given as options `chapter-regex` and `part-regex`.
* Example invocation to split all docx files in a directory on paragraphs with style 'heading 1':
  `calabash/calabash.sh -o result=file:///C:/…/result.xml  split-docx/xpl/split-main.xpl dir=path-to-docx-dir chapter-regex="heading\s*1" debug=yes debug-dir-uri=file:///…/debug`

You could provide customer specific `split-docx/conf.xsl` filed to change target file names of split chunks. Therefore the pipeline must be invoked with a params input port.

The subpipelines can also be used to split on bookmarks etc.

## Setup for Standalone Invocation

You need to set up a complete transpect project:

* Create a project folder, say, split-docx-frontend, and change to it.
* `git clone https://github.com/transpect/calabash-frontend calabash --recurse-submodules`
* `git clone https://github.com/transpect/cascade`
* `git clone https://github.com/transpect/docx2hub`
* `git clone https://github.com/transpect/docx_modify-lib`
* `git clone https://github.com/transpect/split-docx`
* `git clone https://github.com/transpect/xproc-util`
* `git clone https://github.com/transpect/xslt-util`
* Create a directory xmlcatalog and inside an XML catalog file called catalog.xml with this content:
```xml
<catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">
  <rewriteURI uriStartString="http://this.transpect.io/" rewritePrefix="../"/>
  <nextCatalog catalog="../split-docx/xmlcatalog/catalog.xml"/>
  <nextCatalog catalog="../cascade/xmlcatalog/catalog.xml"/>
  <nextCatalog catalog="../xproc-util/xmlcatalog/catalog.xml"/>
  <nextCatalog catalog="../xslt-util/xmlcatalog/catalog.xml"/>
  <nextCatalog catalog="../docx2hub/xmlcatalog/catalog.xml"/>
  <nextCatalog catalog="../docx_modify-lib/xmlcatalog/catalog.xml"/>
</catalog>
```
* 

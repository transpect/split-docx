<?xml version="1.0" encoding="utf-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub="http://transpect.io/docx2hub"
  xmlns:tr="http://transpect.io" 
  xmlns:html="http://www.w3.org/1999/xhtml" 
  version="1.0"
  name="split-docx" 
  type="tr:split-docx">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>This step will split docx file(s)</p>
  </p:documentation>

  <p:input port="params" primary="true" sequence="true">
    <p:empty/>
  </p:input>
  <p:output port="result" primary="true" sequence="true"/>

  <p:option name="dir" required="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Input directory, given as a path or as a URI.</p>
    </p:documentation>
  </p:option>
  <p:option name="outdir" required="false" select="''">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Directory for transient and output files, given as a path or as a URI.
      If empty, will be set to '{$dir}/out/'.</p>
    </p:documentation>
  </p:option>
<!--  <p:option name="result-filenames" required="false" select="''">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p></p>
    </p:documentation>
  </p:option>-->
  <p:option name="part-regex" required="false" select="''"> 
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>a regex that determines parts names. If empty it will not be used</p>
    </p:documentation>
  </p:option>
  <p:option name="chapter-regex" required="false" select="''"> 
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>a regex that determines chapter names. If empty it will not be used</p>
    </p:documentation>
  </p:option>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="split-docx0_scan-dir.xpl"/>
  <p:import href="split-docx1_select-styles.xpl"/>
  <p:import href="split-docx2_finally-split.xpl"/>
  <p:import href="http://transpect.io/cascade/xpl/load-cascaded.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>


  <tr:load-cascaded name="load-split-docx-stylesheet" filename="split-docx/config.xsl">
    <p:input port="paths">
      <p:pipe port="params" step="split-docx"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="required" select="'no'"/>
    <p:with-option name="fallback" select="'http://transpect.io/split-docx/xsl/config.xsl'"/>
  </tr:load-cascaded>

  <p:sink/>

  <tr:split-docx_scan-dir name="scan-styles">
    <p:documentation><p>analyse docxs files for styles</p></p:documentation>

    <p:with-option name="dir" select="$dir"/>
    <p:with-option name="outdir" select="$outdir"/>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:split-docx_scan-dir>
  
  <tr:store-debug pipeline-step="split-docx/01.files-with-styles">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

  <p:xslt name="add-split-as" initial-mode="add-split-as">
    <p:documentation><p>select styles that are relevant, add @split-as</p>
      <p>http://svn/svn/ltxbase/Hubformat/spwf/trunk-git/doc/split/split1.xml</p>
      <p>This can be cascaded later</p>
    </p:documentation>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:with-param name="part-regex" select="$part-regex"/>
    <p:with-param name="chapter-regex" select="$chapter-regex"/>
    <p:input port="stylesheet">
      <p:pipe port="result" step="load-split-docx-stylesheet"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="split-docx/02.styles-with-split-as">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

  <tr:split-docx_styles name="select-styles">
    <p:documentation>
      <p>determine elements for headings, http://svn/svn/ltxbase/Hubformat/spwf/trunk-git/doc/split/split2.xml</p>
      <p>input port gets filelist with @split-as attributes</p>
    </p:documentation>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:split-docx_styles>

  <tr:store-debug pipeline-step="split-docx/03.split-elements">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

  <p:xslt name="add-filename" initial-mode="add-filename">
    <p:documentation><p>select styles that are relevant, add @split-as</p>
      <p>http://svn/svn/ltxbase/Hubformat/spwf/trunk-git/doc/split/split1.xml</p>
    </p:documentation>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
     <p:input port="stylesheet">
      <p:pipe port="result" step="load-split-docx-stylesheet"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="split-docx/04.split-elements-with-filenames">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

  <tr:actual-split-docx name="actual-split">
    <p:documentation>
      <p>splits documents</p>
      <p>input port gets list with splittable elements, their sourcepaths and filenames (http://svn/svn/ltxbase/Hubformat/spwf/trunk-git/doc/split/split3.xml)</p>
    </p:documentation>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:actual-split-docx>

</p:declare-step>

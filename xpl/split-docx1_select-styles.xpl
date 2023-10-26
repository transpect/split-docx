<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:pxf="http://exproc.org/proposed/steps/file" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub="http://transpect.io/docx2hub" xmlns:tr="http://transpect.io"
  xmlns:html="http://www.w3.org/1999/xhtml" version="1.0" 
  name="split-docx_styles"
  type="tr:split-docx_styles">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>Will accept a <code>&lt;files></code> document as posted by the split button.</p>
  </p:documentation>

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>

  <p:input port="source" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Heading selection with @filename attributes in a <code>&lt;files></code> document. Example:</p>
      <pre><code/></pre>
    </p:documentation>
    <p:inline>
      <nodoc/>
    </p:inline>
  </p:input>
  <p:output port="result" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>The input document, enriched with the text and IDs of the found headings.</p>
    </p:documentation>
  </p:output>
  <p:serialization port="result" indent="true"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>

  <p:viewport match="file" name="insert-headings">
    <p:choose>
      <p:when test="/*/@copy-as">
        <pxf:copy>
          <p:with-option name="href" select="/*/@uri"/>
          <p:with-option name="target" select="concat(resolve-uri(@filename, @single-tree), '.docx')"/>
        </pxf:copy>
        <p:identity>
          <p:input port="source">
            <p:pipe port="current" step="insert-headings"/>
          </p:input>
        </p:identity>
      </p:when>
      <p:otherwise>
        <p:xslt name="extract-headings">
          <p:input port="source">
            <p:pipe port="current" step="insert-headings"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
          <p:input port="stylesheet">
            <p:inline>
              <xsl:stylesheet version="2.0" exclude-result-prefixes="#all">
                <xsl:template match="/file[@copy-as]" priority="2">
                  <xsl:copy-of select="."/>
                </xsl:template>
                <xsl:template match="/file">
                  <xsl:variable name="body" as="element(w:body)" 
                    select="document(@single-tree)/w:root/w:document/w:body"/>
                  <xsl:copy>
                    <xsl:copy-of select="@*, node()"/>
                    <headings>
                      <xsl:variable name="headings" as="element(*)*">
                        <xsl:apply-templates select="$body/w:p" mode="extract-headings">
                          <xsl:with-param name="file-spec" select="."/>
                        </xsl:apply-templates>
                      </xsl:variable>
                      <xsl:variable name="unassigned" as="element(*)?" select="$body/*[@srcpath][1][not(@srcpath = $headings/@srcpath)]"/>
                      <xsl:if test="$unassigned">
                        <unassigned>
                          <xsl:apply-templates select="$unassigned//w:t" mode="extract-headings">
                            <xsl:with-param name="file-spec" select="."/>
                          </xsl:apply-templates>
                        </unassigned>
                      </xsl:if>
                      <xsl:sequence select="$headings"/>
                    </headings>
                  </xsl:copy>
                </xsl:template>
                <xsl:template match="*" mode="extract-headings"/>
                <xsl:template match="w:r" mode="extract-headings">
                  <xsl:apply-templates mode="#current"/>
                </xsl:template>
                <xsl:template match="w:t" mode="extract-headings">
                  <xsl:value-of select="."/>
                </xsl:template>
                <xsl:template match="text()" mode="extract-headings"/>
                <xsl:template match="w:p" mode="extract-headings">
                  <xsl:param name="file-spec" as="element(file)"/>
                  <xsl:variable name="bookmarkstart" as="element(w:bookmarkStart)*"
                    select="w:bookmarkStart[for $name in @w:name 
                                            return some $bookmark-instr in $file-spec/bookmark/@*[. = 'true']/name()
                                                   satisfies (starts-with($name, concat('le_tex_', $bookmark-instr)))]"/>
                  <xsl:variable name="split-as-style"
                    select="$file-spec/style[@split-as][@id = current()/w:pPr/w:pStyle/@w:val]" as="element(style)*"/>
                  <xsl:choose>
                    <xsl:when test="count($bookmarkstart) gt 1">
                      <xsl:message>More than one bookmark in p <xsl:copy-of select="."/></xsl:message>
                      <error>More than one bookmark in p <xsl:value-of select="."/></error>
                    </xsl:when>
                    <xsl:when test="count($split-as-style) gt 1">
                      <xsl:message>More than one style/@split-as entry for style id <xsl:value-of
                          select="distinct-values($split-as-style/@id)"/></xsl:message>
                      <error>More than one style/@split-as entry for style id <xsl:value-of
                          select="distinct-values($split-as-style/@id)"/></error>
                    </xsl:when>
                    <xsl:when test="exists($bookmarkstart)">
                      <xsl:variable name="type" select="replace($bookmarkstart/@w:name, '^le_tex_(\w+).+$', '$1')"
                        as="xs:string"/>
                      <xsl:element name="{$type}">
                        <xsl:attribute name="spec" select="'bookmark'"/>
                        <xsl:copy-of select="@srcpath"/>
                        <xsl:apply-templates mode="#current"/>
                      </xsl:element>
                    </xsl:when>
                    <xsl:when test="exists($split-as-style)">
                      <xsl:variable name="type" select="$split-as-style/@split-as" as="xs:string"/>
                      <xsl:element name="{$type}">
                        <xsl:attribute name="style-name" select="$split-as-style/@name"/>
                        <xsl:attribute name="style-id" select="$split-as-style/@id"/>
                        <xsl:attribute name="spec" select="'style'"/>
                        <xsl:copy-of select="@srcpath"/>
                        <xsl:apply-templates mode="#current"/>
                      </xsl:element>
                    </xsl:when>
                  </xsl:choose>
                </xsl:template>
              </xsl:stylesheet>
            </p:inline>
          </p:input>
        </p:xslt>
      </p:otherwise>
    </p:choose>
  </p:viewport>

</p:declare-step>

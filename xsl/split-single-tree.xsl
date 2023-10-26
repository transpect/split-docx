<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:ct="http://schemas.openxmlformats.org/package/2006/content-types"
  xmlns:ep="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub="http://transpect.io/docx2hub"
  exclude-result-prefixes="xs docx2hub"
  version="2.0">

  <xsl:import href="http://transpect.io/docx_modify/xsl/lib/remove-customizations-and-macros.xsl"/>

  <xsl:template match="@* | *" mode="#default export">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/file" mode="#default">
    <xsl:variable name="file-spec" as="element(file)" select="."/>
    <xsl:variable name="heading-srcpaths" select="headings/*/@srcpath" as="xs:string*"/>
    <xsl:variable name="doc" as="document-node(element(w:root))" select="doc(@single-tree)"/>
    <xsl:variable name="sectPrs" as="element(w:sectPr)*" select="$doc/w:root/w:document/w:body//w:sectPr"/>
    <xsl:variable name="unassigned" select="$file-spec/headings/*[not(@srcpath)][1]/@filename" as="attribute(*)?"/>
    <xsl:for-each-group select="$doc/w:root/w:document/w:body/*" 
      group-starting-with="*[if (exists($heading-srcpaths))
                             then @srcpath = $heading-srcpaths
                             else position() = 1]">
      <!-- position() = 1 is for the case when everything is unassigned -->
      <xsl:choose>
        <xsl:when test="@srcpath = $heading-srcpaths
                        and 
                        not($file-spec/headings/*[@srcpath = current()/@srcpath]/@filename)">
          <!-- No @filename attribute means: user does not want this exported -->
        </xsl:when>
        <xsl:when test="@srcpath = $heading-srcpaths">
          <xsl:variable name="heading" select="$file-spec/headings/*[@srcpath = current()/@srcpath]" as="element(*)"/>
          <xsl:call-template name="export-chunk">
            <xsl:with-param name="reduced-to" select="current-group()" tunnel="yes"/>
            <xsl:with-param name="sectPrs" select="$sectPrs" tunnel="yes"/>
            <xsl:with-param name="doc" select="$doc"/>
            <xsl:with-param name="result-href" tunnel="yes"
              select="replace($file-spec/@single-tree, '^(.+/).+$', concat('$1', $heading/@filename, '.xml'))"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$unassigned">
          <!-- If the chunk that comes before the first header should be exported, it will be 
            an unassigned element with a @filename attribute. -->
          <xsl:call-template name="export-chunk">
            <xsl:with-param name="reduced-to" select="current-group()" tunnel="yes"/>
            <xsl:with-param name="sectPrs" select="$sectPrs" tunnel="yes"/>
            <xsl:with-param name="doc" select="$doc"/>
            <xsl:with-param name="result-href" tunnel="yes"
              select="replace($file-spec/@single-tree, '^(.+/).+$', concat('$1', $unassigned, '.xml'))"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise> 
          <!-- discard first group if there is no @filename given for the previously unassigned element -->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template name="export-chunk">
    <xsl:param name="doc" as="document-node(element(w:root))"/>
    <xsl:variable name="docrel-ids" as="xs:string*" select="docx2hub:docrel-ids($doc, current-group())"/>
    <xsl:variable name="containerrel-ids" as="xs:string*" select="docx2hub:containerrel-ids($doc)"/>
    <xsl:apply-templates select="$doc" mode="docx2hub:modify">
      <xsl:with-param name="docrel-ids" select="$docrel-ids" tunnel="yes"/>
      <xsl:with-param name="containerrel-ids" select="$containerrel-ids" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="w:root" mode="docx2hub:modify">
    <xsl:param name="result-href" as="xs:string" tunnel="yes"/>
    <xsl:result-document href="{$result-href}">
      <xsl:next-match/>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="w:body" mode="docx2hub:modify">
    <xsl:param name="reduced-to" as="element(*)*" tunnel="yes"/>
    <xsl:param name="sectPrs" as="element(w:sectPr)*" tunnel="yes"/>
    <xsl:variable name="next-sectPr" select="($sectPrs[. &gt;&gt; $reduced-to[last()]])[1]" as="element(w:sectPr)?"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="$reduced-to, 
                                   if ($reduced-to[descendant-or-self::w:sectPr])
                                   then ()
                                   else $next-sectPr" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <!-- transform files from TouchOSC Editor -->
  <!-- adding plain text attributes for tabpage name, control name, control text -->
  <!-- zcat my.touchosc | xmlstarlet fo > my.xml -->
  <!-- xmlstarlet tr stylesheet.xsl my.xml -->
  <!-- //tb/1704 -->

  <!-- <xsl:import href="base64encoder.xsl"/> -->
  <xsl:import href="base64decoder.xsl"/>

  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

  <!-- <xsl:strip-space elements="*"/> -->
  <!-- =============================== -->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- =============================== -->
  <xsl:template match="layout">
    <xsl:element name="layout">
      <xsl:copy-of select="@*" />
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- =============================== -->
  <xsl:template match="tabpage">
    <xsl:element name="tabpage">
       <xsl:copy-of select="@*" />

       <xsl:attribute name="n">
          <xsl:call-template name="convertBase64ToAscii">
            <xsl:with-param name="base64String">
              <xsl:value-of select="@name"/>
            </xsl:with-param>
          </xsl:call-template>
       </xsl:attribute>
       <xsl:if test="@osc_cs">
         <xsl:attribute name="custom_osc_plain">
            <xsl:call-template name="convertBase64ToAscii">
              <xsl:with-param name="base64String">
                <xsl:value-of select="@osc_cs"/>
              </xsl:with-param>
            </xsl:call-template>
         </xsl:attribute>
       </xsl:if>
       <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- =============================== -->
  <xsl:template match="control">
    <xsl:element name="control">
      <xsl:copy-of select="@*" />
      <xsl:attribute name="n">
          <xsl:call-template name="convertBase64ToAscii">
            <xsl:with-param name="base64String">
              <xsl:value-of select="@name"/>
            </xsl:with-param>
          </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="t">
          <xsl:call-template name="convertBase64ToAscii">
            <xsl:with-param name="base64String">
              <xsl:value-of select="@text"/>
            </xsl:with-param>
          </xsl:call-template>
      </xsl:attribute>
       <xsl:if test="@osc_cs">
         <xsl:attribute name="custom_osc_plain">
            <xsl:call-template name="convertBase64ToAscii">
              <xsl:with-param name="base64String">
                <xsl:value-of select="@osc_cs"/>
              </xsl:with-param>
            </xsl:call-template>
         </xsl:attribute>
       </xsl:if>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>

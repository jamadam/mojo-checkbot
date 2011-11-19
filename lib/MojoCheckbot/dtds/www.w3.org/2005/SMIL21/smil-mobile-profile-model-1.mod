<!-- ====================================================================== -->
<!-- SMIL 2.1 Document Model Module ======================================= -->
<!-- file: smil-model-extended-mobile-1.mod

     This is SMIL 2.1.

        Copyright: 1998-2005 W3C (MIT, ERCIM, Keio), All Rights
        Reserved.  See http://www.w3.org/Consortium/Legal/.

        Author: Warner ten Kate, Jacco van Ossenbruggen, Aaron Cohen
        Editor for SMIL 2.1: Sjoerd Mullender, CWI
        1.1.2.5
        2005/06/23 09:07:46

     This DTD module is identified by the PUBLIC and SYSTEM identifiers:

     PUBLIC "-//W3C//ENTITIES SMIL 2.1 Document Model 1.0//EN"
     SYSTEM "http://www.w3.org/2005/SMIL21/smil-mobile-profile-model-1.mod"

     ====================================================================== -->

<!--
        This file defines the SMIL 2.1 Mobile Profile
        Document Model.  All attributes and content models are defined
        in the second half of this file.  We first start with some
        utility definitions.  These are mainly used to simplify the
        use of Modules in the second part of the file.

-->

<!-- ================== Util: Head ======================================== -->
<!ENTITY % SMIL.head-meta.content       "%SMIL.metadata.qname;">
<!ENTITY % SMIL.head-layout.content     "%SMIL.layout.qname; 
                                       | %SMIL.switch.qname;">
<!ENTITY % SMIL.head-transition.content "%SMIL.transition.qname;+">
<!ENTITY % SMIL.head-media.content      "%SMIL.paramGroup.qname;+">

<!--=================== Util: Body - Content Control ====================== -->
<!ENTITY % SMIL.content-control "%SMIL.switch.qname; | %SMIL.prefetch.qname;">
<!ENTITY % SMIL.content-control-attrs "%SMIL.Test.attrib; 
                                       %SMIL.skip-content.attrib;">

<!--=================== Util: Body - Media ========================= -->

<!ENTITY % SMIL.media-object "%SMIL.audio.qname; 
                              | %SMIL.video.qname; 
                              | %SMIL.animation.qname;
                              | %SMIL.text.qname;
                              | %SMIL.img.qname;
                              | %SMIL.textstream.qname;
                              | %SMIL.ref.qname;">

<!--=================== Util: Body - Timing =============================== -->
<!ENTITY % SMIL.BasicTimeContainers.class "%SMIL.par.qname; 
                                         | %SMIL.seq.qname;">

<!ENTITY % SMIL.timecontainer.class   "%SMIL.BasicTimeContainers.class;">

<!ENTITY % SMIL.timecontainer.content "%SMIL.timecontainer.class; 
                                     | %SMIL.media-object;
                                     | %SMIL.content-control;
                                     | %SMIL.a.qname;">

<!ENTITY % SMIL.smil-basictime.attrib "
 %SMIL.BasicInlineTiming.attrib;
 %SMIL.BasicInlineTiming-deprecated.attrib;
 %SMIL.MinMaxTiming.attrib;
">

<!ENTITY % SMIL.timecontainer.attrib "
 %SMIL.BasicInlineTiming.attrib;
 %SMIL.BasicInlineTiming-deprecated.attrib;
 %SMIL.MinMaxTiming.attrib;
">

<!-- ====================================================================== -->
<!-- ====================================================================== -->
<!-- ====================================================================== -->

<!-- 
     The actual content model and attribute definitions for each module 
     sections follow below.
-->

<!-- ================== Content Control =================================== -->
<!ENTITY % SMIL.BasicContentControl.module  "INCLUDE">
<!ENTITY % SMIL.CustomTestAttributes.module "IGNORE">
<!ENTITY % SMIL.PrefetchControl.module      "INCLUDE">
<!ENTITY % SMIL.skip-contentControl.module  "INCLUDE">

<!ENTITY % SMIL.switch.content "((%SMIL.timecontainer.class;
                                | %SMIL.media-object;
                                | %SMIL.content-control;
                                | %SMIL.a.qname; 
                                | %SMIL.area.qname; 
                                | %SMIL.anchor.qname;)*
                                | %SMIL.layout.qname;*)">

<!ENTITY % SMIL.switch.attrib "%SMIL.Test.attrib;">
<!ENTITY % SMIL.prefetch.attrib "
 %SMIL.timecontainer.attrib; 
 %SMIL.MediaClip.attrib; 
 %SMIL.MediaClip.attrib.deprecated; 
 %SMIL.Test.attrib; 
 %SMIL.skip-content.attrib; 
">

<!-- ================== Layout ============================================ -->
<!ENTITY % SMIL.BasicLayout.module            "INCLUDE">
<!ENTITY % SMIL.AudioLayout.module            "INCLUDE">
<!ENTITY % SMIL.MultiWindowLayout.module      "IGNORE">
<!ENTITY % SMIL.SubRegionLayout.module        "IGNORE">
<!ENTITY % SMIL.AlignmentLayout.module        "INCLUDE">
<!ENTITY % SMIL.OverrideLayout.module         "IGNORE">
<!ENTITY % SMIL.BackgroundTilingLayout.module "INCLUDE">

<!ENTITY % SMIL.layout.content "(%SMIL.region.qname;
                               | %SMIL.root-layout.qname; 
                               | %SMIL.regPoint.qname;)*">
<!ENTITY % SMIL.region.content "(%SMIL.region.qname;)*">
<!ENTITY % SMIL.rootlayout.content "EMPTY">
<!ENTITY % SMIL.regPoint.content "EMPTY">

<!ENTITY % SMIL.layout.attrib          "%SMIL.Test.attrib;">
<!ENTITY % SMIL.rootlayout.attrib      "%SMIL.content-control-attrs;">
<!ENTITY % SMIL.region.attrib          "%SMIL.content-control-attrs;">
<!ENTITY % SMIL.regPoint.attrib        "%SMIL.content-control-attrs;">

<!-- ================== Linking =========================================== -->
<!ENTITY % SMIL.LinkingAttributes.module "INCLUDE">
<!ENTITY % SMIL.BasicLinking.module      "INCLUDE">
<!ENTITY % SMIL.ObjectLinking.module     "IGNORE">

<!ENTITY % SMIL.a.content      "(%SMIL.timecontainer.class;|%SMIL.media-object;|
                                 %SMIL.content-control;)*">
<!ENTITY % SMIL.area.content   "EMPTY">
<!ENTITY % SMIL.anchor.content "EMPTY">

<!ENTITY % SMIL.a.attrib      "%SMIL.smil-basictime.attrib; %SMIL.Test.attrib;">
<!ENTITY % SMIL.area.attrib   "%SMIL.smil-basictime.attrib; %SMIL.content-control-attrs;"> 
<!ENTITY % SMIL.anchor.attrib "%SMIL.smil-basictime.attrib; %SMIL.content-control-attrs;"> 

<!-- ================== Media  ============================================ -->
<!ENTITY % SMIL.BasicMedia.module                     "INCLUDE">
<!ENTITY % SMIL.MediaClipping.module                  "INCLUDE">
<!ENTITY % SMIL.MediaClipping.deprecated.module       "INCLUDE">
<!ENTITY % SMIL.MediaClipMarkers.module               "IGNORE">
<!ENTITY % SMIL.MediaParam.module                     "INCLUDE">
<!ENTITY % SMIL.BrushMedia.module                     "IGNORE">
<!ENTITY % SMIL.MediaAccessibility.module             "INCLUDE">

<!ENTITY % SMIL.media-object.content "(%SMIL.switch.qname;
                                     | %SMIL.anchor.qname;
                                     | %SMIL.area.qname;
                                     | %SMIL.param.qname;)*">
<!ENTITY % SMIL.media-object.attrib "
  %SMIL.BasicInlineTiming.attrib;
  %SMIL.BasicInlineTiming-deprecated.attrib;
  %SMIL.MinMaxTiming.attrib;
  %SMIL.endsync.media.attrib;
  %SMIL.fill.attrib;
  %SMIL.Test.attrib;
  %SMIL.regionAttr.attrib;
  %SMIL.Transition.attrib;
  %SMIL.backgroundColor.attrib;
  %SMIL.backgroundColor-deprecated.attrib;
  %SMIL.RegistrationPoint.attrib;
  %SMIL.fit.attrib;
  %SMIL.tabindex.attrib;
  %SMIL.MediaObject.attrib;
">

<!ENTITY % SMIL.param.attrib        "%SMIL.content-control-attrs;">
<!ENTITY % SMIL.paramGroup.attrib   "%SMIL.skip-content.attrib;">

<!-- ================== Metadata ========================================== -->
<!ENTITY % SMIL.meta.content     "EMPTY">
<!ENTITY % SMIL.meta.attrib      "%SMIL.skip-content.attrib;">

<!ENTITY % SMIL.metadata.content "EMPTY">
<!ENTITY % SMIL.metadata.attrib  "%SMIL.skip-content.attrib;">

<!-- ================== Structure ========================================= -->
<!ENTITY % SMIL.Structure.module "INCLUDE">
<!ENTITY % SMIL.smil.content "(%SMIL.head.qname;?,%SMIL.body.qname;?)">
<!ENTITY % SMIL.head.content "(
         %SMIL.meta.qname;*,
         ((%SMIL.head-meta.content;),      %SMIL.meta.qname;*)?,
         ((%SMIL.head-layout.content;),    %SMIL.meta.qname;*)?,
         ((%SMIL.head-transition.content;),%SMIL.meta.qname;*)?,
         ((%SMIL.head-media.content;),     %SMIL.meta.qname;*)?
)">
<!ENTITY % SMIL.body.content "(%SMIL.timecontainer.class;|%SMIL.media-object;|
                          %SMIL.content-control;|a)*">

<!ENTITY % SMIL.smil.attrib "%SMIL.Test.attrib;">
<!ENTITY % SMIL.body.attrib "
        %SMIL.timecontainer.attrib; 
        %SMIL.Description.attrib;
        %SMIL.fill.attrib;
">

<!-- ================== Transitions ======================================= -->
<!ENTITY % SMIL.BasicTransitions.module            "INCLUDE">
<!ENTITY % SMIL.TransitionModifiers.module         "IGNORE">
<!ENTITY % SMIL.InlineTransitions.module           "IGNORE">
<!ENTITY % SMIL.FullScreenTransitionEffects.module "INCLUDE">

<!ENTITY % SMIL.transition.content "EMPTY">
<!ENTITY % SMIL.transition.attrib "%SMIL.content-control-attrs;">

<!-- ================== Timing ============================================ -->
<!ENTITY % SMIL.BasicInlineTiming.module            "INCLUDE">
<!ENTITY % SMIL.SyncbaseTiming.module               "IGNORE">
<!ENTITY % SMIL.EventTiming.module                  "INCLUDE">
<!ENTITY % SMIL.WallclockTiming.module              "IGNORE">
<!ENTITY % SMIL.MultiArcTiming.module               "IGNORE">
<!ENTITY % SMIL.MediaMarkerTiming.module            "IGNORE">
<!ENTITY % SMIL.MinMaxTiming.module                 "INCLUDE">
<!ENTITY % SMIL.BasicTimeContainers.module          "INCLUDE">
<!ENTITY % SMIL.BasicExclTimeContainers.module      "IGNORE">
<!ENTITY % SMIL.BasicPriorityClassContainers.module "IGNORE">
<!ENTITY % SMIL.PrevTiming.module                   "INCLUDE">
<!ENTITY % SMIL.RestartTiming.module                "IGNORE">
<!ENTITY % SMIL.SyncBehavior.module                 "IGNORE">
<!ENTITY % SMIL.SyncBehaviorDefault.module          "IGNORE">
<!ENTITY % SMIL.RestartDefault.module               "IGNORE">
<!ENTITY % SMIL.fillDefault.module                  "IGNORE">

<!ENTITY % SMIL.par.attrib "
        %SMIL.endsync.attrib; 
        %SMIL.fill.attrib;
        %SMIL.timecontainer.attrib; 
        %SMIL.Test.attrib; 
        %SMIL.regionAttr.attrib;
">
<!ENTITY % SMIL.seq.attrib "
        %SMIL.fill.attrib;
        %SMIL.timecontainer.attrib; 
        %SMIL.Test.attrib; 
        %SMIL.regionAttr.attrib;
">
<!ENTITY % SMIL.par.content "(%SMIL.timecontainer.content;)*">
<!ENTITY % SMIL.seq.content "(%SMIL.timecontainer.content;)*">

<!-- end of smil-mobile-profile-model-1.mod -->

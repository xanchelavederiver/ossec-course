<script setup>
/**
 * SrcRef — the per-slide pointer at the demo script or source file a slide
 * shows: «См. demos/07-user-defaults.sh».
 *
 * Stays in the flow as the slide's closing line: aligned with the rest of the
 * content and above the footer that carries «Источники: …» and the slide
 * number. Place it last, at the slide's top level, before <Refs>:
 *   <SrcRef>См. <code>demos/07-user-defaults.sh</code>.</SrcRef>
 */
</script>

<template>
  <div class="slide-srcref">
    <slot />
  </div>
</template>

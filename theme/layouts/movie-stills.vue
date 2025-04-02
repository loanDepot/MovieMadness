<script setup lang="ts">
import { defineComponent } from 'vue'

import ThemeLayout from './theme-layout.vue'

const components = defineComponent({ ThemeLayout })
const props = defineProps<{
  name: string
  cover: string
  images: Array<object>
  leftClass?: string
  rightClass?: string
  imageClass?: string
  bleed?: Boolean
  equal?: Boolean
}>();

</script>

<template>
  <theme-layout class="cover heroGrid">
    <div id="name" class="content h-full place-content-center z2">
      <h1>{{name}}</h1>
    </div>
    <div id="gallery">
      <div id="poster">
        <img :src="cover" />
        <div v-click>
          <slot />
        </div>
      </div>
      <div v-for="(image, index) in props.images"><img :src="image.url"><a :href="'#lightbox-' + $page + '-' + index">{{
        image.caption }}</a></div>
    </div>
    <div v-for="(image, index) in props.images" class="lightbox" :id="'lightbox-' + $page + '-' + index">
      <div class="image"><img :src="image.url">
        <div class="title">{{ image.caption }}</div><a class="close" href="#gallery"></a>
      </div>
    </div>
  </theme-layout>
</template>

<style scoped>
@keyframes fadeOut {
  from {
    opacity: 1;
    visibility: visible;
  }

  to {
    opacity: 0;
    visibility: hidden;
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }

  to {
    opacity: .9;
  }
}

#name {
  top: 10%;
  position: fixed;
  transition: opacity 2s ease;
  animation-name: fadeOut;
  animation-delay: 1s;
  animation-duration: 2s;
  animation-fill-mode: forwards;

  &::before {
    background: none;
  }

  h1 {
    font-size: 3em;
    color: #fff;
    text-shadow: 0 0 10px #000;

    &::before {
      background: var(--slidev-theme-default-headingBg);
    }
  }
}

.slidev-vclick-target {
  transition: opacity 100ms ease;
  visibility: visible;
}

.slidev-vclick-hidden {
  opacity: 0;
  pointer-events: none;
  visibility: hidden;
}


#poster>div {
  /*
  opacity: 0;
  mix-blend-mode: screen;
  animation-name: fadeIn;
  animation-delay: 3s;
  animation-duration: 3s;
  animation-fill-mode: forwards; */
  font: .75em sans-serif;
  position: absolute;
  background-color: #ffffff;
  color: #000;
  display: block !important;
  height: 100%;
  width: 100%;
  padding: 1em;
}

.bg-main #name {
  opacity: 0;
  animation-delay: 0s;
  animation-direction: reverse;
}

/* $size: 6;*/
#gallery {
  display: grid;
  height: 100%;
  grid-template: repeat(5 /*size*/, 1fr) / repeat(5 /*size*/, 1fr);
  /* transform: rotateZ(25deg); */
  grid-gap: 0.15em;

  & > div {
    /* //Grid Structure */
    &:nth-child(1) {
      grid-column: span 1 !important;
      grid-row: span 3 !important;
    }
    &:nth-child(6n + 1) {
      grid-column: span 2;
      grid-row: span 2;
    }
    &:nth-child(2) {
      grid-column: span 3;
      grid-row: span 3;
    }
    /* &:nth-child(3n) {
      img {
        transform: rotateZ(25deg) scale(1.5) translateX(-20%) translateY(20%);
      }
    } */
    &:nth-child(4) {
      grid-column: span 1;
      grid-row: span 2;
    }
    & > a {
      opacity: 0;
      position: absolute;
      color: #000;
      background-color: #000;
      font: bold 1em "Helvetica";
      text-shadow: 0 -1px 5px #fff, -1px 0px 5px #fff, 0 1px 5px #fff,
        1px 0px 5px #fff;
      padding: 2rem;
      mix-blend-mode: difference;
      width: 100%;
      height: 100%;
      transition: all ease 1s;
    }
    & > img {
      width: 100%;
      min-height: 100%;
      transition: all ease 1s;
      align-self: self-start;
    }
    &:hover {
      img {
        filter: blur(4px);
      }
      a {
        opacity: 1;
      }
      /* div {
        opacity: 1;
      } */
    }
  }
  & > div {
    overflow: hidden;
    position: relative;
    box-shadow: 0 2px 8px 0 rgba(#000, 0.2), 0 3px 20px 0 rgba(#000, 0.19);
  }
  div,
  a {
    display: flex;
    text-decoration: none;
  }
}
/* *** lightbox */
[id^="lightbox-"] {
  &:target {
    opacity:1;
    pointer-events:inherit;
    img{
      filter:blur(0);
    }
  }
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(black, 0.5);
  display: flex;
  opacity:0;
  transition: opacity 450ms ease-in-out;
  align-items: baseline;
  justify-content: center;
  pointer-events: none;
  background-color: #ffffffcc;
  .image {
    max-height: 90%;
    max-width: 90%;
    position: relative;
    color: #fff;
    &:hover > a.close {
      opacity: 1;
      transform: scale(1, 1);
    }
    &:hover > .title {
      opacity: 1;
      transform: translateY(-3px); /* Fix extra line at end */
      &::after{
        opacity:1;
      }
    }
    & > * {
      transition: all 450ms ease-in-out;
    }
  }
  .title {
    display: block;
    margin: 0;
    padding: 1em;
    position: absolute;
    bottom: 0;
    width: 100%;
    transform: translateY(50%);
    font-size:1.5em;
    opacity:0;
    &::after{
      content: ' ';
      background-color: rgba(black, 0.4);
      bottom:0;
      left:0;
      height:100%;
      width:100%;
      position:absolute;
      transition: all 350ms ease-in-out 250ms;
      opacity:0;
      transform-origin:bottom;
      mix-blend-mode: soft-light;
    }
  }
  img {
    max-height: 600px;
    max-width: 100%;
    margin: 0;
    padding: 0;
    filter: blur(50px);
  }
  a.close {
    width: 2em;
    height: 2em;
    position: absolute;
    right: 0;
    top: 0;
    background-color: rgba(black, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    transform: scale(0, 0);
    opacity: 0;
    transform-origin: right top;
    text-decoration:none;
    color:#fff;
    &::after {
      content: "X";
    }
  }
}

</style>

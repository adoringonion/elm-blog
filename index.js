import "./style.css";
import hljs from "highlight.js";
import load from 'little-loader'
import "highlight.js/styles/solarized-dark.css";
// @ts-ignore
window.hljs = hljs;
const { Elm } = require("./src/Main.elm");
const pagesInit = require("elm-pages");

load("https://www.googletagmanager.com/gtag/js?id=UA-147049916-2", () => {
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'UA-147049916-2');
})
pagesInit({
  mainElmModule: Elm.Main
});


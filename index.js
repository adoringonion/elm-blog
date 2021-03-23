import "./style.css";
import hljs from "highlight.js";
import "highlight.js/styles/solarized-dark.css";
// @ts-ignore
window.hljs = hljs;
const { Elm } = require("./src/Main.elm");
const pagesInit = require("elm-pages");

pagesInit({
  mainElmModule: Elm.Main
});


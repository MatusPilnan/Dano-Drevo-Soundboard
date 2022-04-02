import "./index.css";

import flags from "./flags.json";

import { Elm } from "./elm/Main.elm";

const app = Elm.Main.init({ node: document.getElementById("app"), flags });

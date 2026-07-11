import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { OnboardAvatar } from "./OnboardAvatar";
import "./styles.css";

const screen = new URLSearchParams(window.location.search).get("screen");
const Root = screen === "onboard" ? OnboardAvatar : App;

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Root />
  </StrictMode>,
);

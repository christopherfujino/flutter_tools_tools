// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Initialize button with user's preferred color
let changeColor = document.getElementById("changeColor");

const goCrashButton = document.getElementById("go-crash");

// When the button is clicked, inject func into current page
goCrashButton.addEventListener("click", async () => {
  let [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  console.log(tab);

  console.log();
  const executionsResults = await chrome.scripting.executeScript({
    target: { tabId: tab.id },
    func: goCrash,
  });
  console.log("execution results:");
  console.log(executionsResults);
});

function goCrash() {
  console.log("Sort the crashes!");
  alert("Hi there!");
}

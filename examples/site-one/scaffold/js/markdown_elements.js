// This was inspired by Strapdown.js, but is just much more simple,
// using just raw marked.js

function processMarkdownElement(markdownEl) {
  var mdText = markdownEl.innerHTML;
  
  var newNode = document.createElement('div');
  newNode.className = 'rabl-rendered-markdown';
  
  markdownEl.parentNode.replaceChild(newNode, markdownEl);
  
  var html = marked(mdText);
  newNode.innerHTML = html;
}

function processMarkdownElementById(id) {
  return processMarkdownElement( document.getElementById(id) );
}


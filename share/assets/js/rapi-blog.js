
function rablActivateTab(event,name) {

  var fn;
  fn = function(node,cls) {
    if(!node || !cls) { return null; }
    return node.classList.contains(cls)
      ? node
      : fn(node.parentElement,cls);
  };
  
  var topEl = fn(event.target,'ra-rowdv-select');
  
  if(
    // Do not process tab change during record update
    !topEl || topEl.classList.contains('editing-record')
  ) { return false; }
  
  name == 'preview'
    ? topEl.classList.add   ('rabl-preview-mode')
    : topEl.classList.remove('rabl-preview-mode');
  
  var links = topEl.getElementsByClassName('tab-link');
  var conts = topEl.getElementsByClassName('tab-content');
  
  for (i = 0; i < links.length; i++) {
    var el = links[i];
    el.classList.remove('active');
    el.classList.remove('inactive');
    if(el.classList.contains(name)) {
      el.classList.add('active');
    }
    else {
      el.classList.add('inactive');
    }
  }
  
  for (i = 0; i < conts.length; i++) {
    var el = conts[i];
    if(el.classList.contains(name)) {
      var iframe = el.getElementsByTagName('iframe')[0];
      if(iframe) {
        // reload the iframe:
        iframe.src = iframe.src;
      }
      el.style.display = 'block';
    }
    else {
      el.style.display = 'none';
    }
  }
  
}

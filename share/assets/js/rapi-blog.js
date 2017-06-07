
function rablActivateTab(event,name) {

  var fn;
  fn = function(node) {
    if(!node) { return null; }
    return node.classList.contains('ra-rowdv-select')
      ? node
      : fn(node.parentElement);
  };
  
  var topEl = fn(event.target);
  
  if(
    // Do not process tab change during record update
    !topEl || topEl.classList.contains('editing-record')
  ) { return false; }
  
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

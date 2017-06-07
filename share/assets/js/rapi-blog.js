
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
  
  // This is a reliable way to get the parent appdv element since we know 
  // datastore 'create' is not allowed in this context (and this is the 
  // element we want to munge the dsapi css class flag for)
  var appdvEl = fn(topEl,'ra-dsapi-deny-create');
  if(!appdvEl) { throw "unable to find appdv element (unexpected error)"; }
  
  name == 'preview'
    ? appdvEl.classList.add   ('ra-dsapi-deny-update')
    : appdvEl.classList.remove('ra-dsapi-deny-update');
  
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

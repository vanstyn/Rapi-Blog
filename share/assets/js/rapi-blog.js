
function rablActivateTab(event) {
  var tab1 = event.target.nextElementSibling;
  var tab2 = tab1.nextElementSibling;
  
  if(tab1.style.display == 'none') {
    tab2.style.display = 'none';
    tab1.style.display = 'block';
  }
  else if(tab2.style.display == 'none') {
  
    var iframe = tab2.getElementsByTagName('iframe')[0];
    if(iframe) {
      iframe.src = iframe.src;
    }
  
    tab1.style.display = 'none';
    tab2.style.display = 'block';
  }

}

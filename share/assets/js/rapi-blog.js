
function rablInitPreviewIframe(iframe,src) {
  if(!src) { throw "rablInitPreviewIframe() requires src as second argument"; }

  var AppDV = rablGetAppDV(iframe);
  
  if(!iframe.rablDoAjaxLoad) {
  
    // this disables click/nav events
    iframe.contentDocument.addEventListener('click',function(e){ 
      e.stopPropagation(); 
      e.preventDefault(); 
    });
  
    // We're doing this manually instead of just setting src to ensure we have control
    // of exactly when and why requests happen. This is important for dev, but may not
    // actually be needed and we can do it the normal way
    iframe.rablDoAjaxLoad = function() {
      var xreq = new XMLHttpRequest();
      xreq.onload = function() {
        iframe.contentWindow.document.open('text/html', 'replace');
        iframe.contentWindow.document.write([
          '<base href="',src,'"/>',
          xreq.responseText
        ].join(""));
        iframe.contentWindow.document.write();
        iframe.contentWindow.document.close();
      };
      xreq.open("GET", src);
      xreq.send();
    }
    if(!AppDV.rablFirstLoad) {
      iframe.rablDoAjaxLoad();
      AppDV.rablFirstLoad = true;
    }
  }
}


function rablGetParentEl(node,cls) {
  if(!node || !cls) { return null; }
  return node.classList.contains(cls)
    ? node
    : rablGetParentEl(node.parentElement,cls);
}


function rablActivateTab(target,name,extra) {
  //console.log(' --> rablActivateTab ('+name+')');
  
  var topEl = rablGetParentEl(target,'rapi-blog-postview');
  
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
      //rablReloadPreviewIframe(el,500);
      el.style.display = 'block';
    }
    else {
      el.style.display = 'none';
    }
  }
  
  if(name == 'source' && extra == 'edit') {
    var controlEl = topEl.getElementsByClassName('edit-record-toggle')[0];
    if(controlEl) {
      var editEl = controlEl.getElementsByClassName('edit')[0];
      if(editEl) {
        topEl._editFromPreview = true;
        editEl.click();
      }
    
    }
  
  }
  
}


function rablGetAppDV(el) {
  var AppDV = null;
  var appdvEl = rablGetParentEl(el,'ra-dsapi-deny-create');
  if(appdvEl) {
    AppDV = Ext.getCmp(appdvEl.id);
    if(AppDV && !AppDV.rablInitialized) {
    
      AppDV.getPreviewIframe = function() {
        return AppDV.el.dom.getElementsByClassName('preview-iframe')[0];
      };
    
      AppDV.rablIframeReloadTask = new Ext.util.DelayedTask(function(){
        var iframe = AppDV.getPreviewIframe();
        if(iframe && iframe.rablDoAjaxLoad) {
           // Call the special, manual ajax load function:
           iframe.rablDoAjaxLoad();
        }
      },AppDV);
      
      AppDV.store.on('buttontoggle',function() {
        if(el._editFromPreview && !this.currentEditRecord) {
          delete el._editFromPreview;
          rablActivateTab(el,'preview');
        }
      },AppDV);

      AppDV.store.on('save',function() {
        AppDV.rablIframeReloadTask.delay(50);
      },AppDV);

      AppDV.rablInitialized = true;
    }
  }
  return AppDV;
}

// Uses RapidApp's mutation observers to dynamically initialize the tab state
ready('.rapi-blog-postview', function(el) {
  rablGetAppDV(el);
  rablActivateTab(el,'preview');
});


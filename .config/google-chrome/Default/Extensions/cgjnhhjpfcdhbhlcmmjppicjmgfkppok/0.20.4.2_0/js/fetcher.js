var g = {};
function getParent(child, selector){
  var target = child;
  while(target && !target.querySelector(selector)){
    if (target.parentNode && target.parentNode.tagName == 'BODY') {
      return target;
    }
    if (target.parentNode && target.parentNode.querySelector(selector)) {
      return target;
    } else {
      target = target.parentNode;
    }
  }
  return null;
}
function getText(s, html, parent){
  var q = parent ? parent.querySelector(s) : qS(s);
  var t = 'textContent';
  if(q && q.querySelectorAll('br').length){t = 'innerHTML';}
  if(q && html && q.querySelectorAll('a').length){t = 'innerHTML';}
  return q ? q[t] : "";
}
function getDOM(html){
  var doc;
  if(document.implementation){
    doc = document.implementation.createHTMLDocument('');
    doc.documentElement.innerHTML = html;
  }else if(DOMParser){
    doc = (new DOMParser).parseFromString(html, 'text/html');
  }else{
    doc = document.createElement('div');
    doc.innerHTML = html;
  }
  return doc;
}
function quickSelect(s){
  var method = false;
  switch(s){
    case /#\w+$/.test(s):
      method = 'getElementById'; break;
    case /\.\w+$/.test(s):
      method = 'getElementsByClassName'; break;
  }
  return method;
}
function qS(s){var k = document[quickSelect(s) || 'querySelector'](s);return k&&k.length ? k[0] : k;}
function qSA(s){return document[quickSelect(s) || 'querySelectorAll'](s);}
function padZero(str, len) {
  str = str.toString();
  while (str.length < len) {
    str = '0' + str;
  }
  return str;
} 
function parseTime(t, isDate){
  var d = isDate ? t : new Date(t * 1000);
  return d.getFullYear() + '-' + padZero(d.getMonth() + 1, 2) + '-' +
    padZero(d.getDate(), 2) + ' ' + padZero(d.getHours(), 2) + ':' +
    padZero(d.getMinutes(), 2) + ':' + padZero(d.getSeconds(), 2);
}
function parseQuery(s){
  var data = {};
  var n = s.split("&");
  for(var i=0; i<n.length; i++){
    var t = n[i].split("=");
    data[t[0]] = t[1];
  }
  return data;
}
function parseFbSrc(s, fb) {
  if (fb) {
    return s.replace(/s\d{3,4}x\d{3,4}\//g, '');
  } else if (!s.match(/\/fr\/|_a\.jpg|1080x/)) {
    return s.replace(/c\d+\.\d+\.\d+\.\d+\//, '')
      .replace(/\w\d{3,4}x\d{3,4}\//g, s.match(/\/e\d{2}\//) ? '' : 'e15/');
  }
  return s;
}
function parsePos(n) {
  return +((n * 100).toFixed(3));
}
function getFbid(s){
  if (!s || !s.length) {
    return false;
  }
  var fbid = s.match(/fbid=(\d+)/);
  if(!fbid){
    if(s.match('opaqueCursor')){
      var index = s.indexOf('/photos/');
      if(index != -1){
        fbid = getFbid(s.slice(index + 8));
        if(fbid){
          return fbid;
        }
      }
      if(!fbid){
        fbid = s.match(/\/([0-9]+)\//);
        if(!fbid){
          fbid = s.match(/([0-9]{5,})/);
        }
      }
    } else if (s.match('&') && !s.match(/photos|videos/)) {
      try{
        fbid = s.slice(s.indexOf('=') + 1, s.indexOf('&'));
      }catch(e){}
      return fbid ? fbid : false;
    } else {
      // id for page's photos / video album
      fbid = s.match(/\/(?:photos|videos)(?:\/[\w\d\.-]+)*\/(\d+)/);
    }
  }
  return fbid && fbid.length ? fbid[1] : false;
}
function getSharedData(response) {
  var html = response;
  var doc = getDOM(html);
  s = doc.querySelectorAll('script');
  for (i=0; i<s.length; i++) {
    if (!s[i].src && s[i].textContent.indexOf('_sharedData') > 0) {
      s = s[i].textContent;
      break;
    }
  }
  return JSON.parse(s.match(/({".*})/)[1]);
}
function extractJSON(str) {
  // http://stackoverflow.com/questions/10574520/
  var firstOpen, firstClose, candidate;
  firstOpen = str.indexOf('{', firstOpen + 1);
  var countOpen = 0, countClose = 0;
  do {
    countOpen++;
    firstClose = str.lastIndexOf('}');
    if (firstClose <= firstOpen) {
      return null;
    }
    countClose = 0;
    do {
      countClose++;
      candidate = str.substring(firstOpen, firstClose + 1);
      var res;
      try {
        res = JSON.parse(candidate);
        return res;
      } catch (e) {}
      try {
        res = eval("(" + candidate + ")");
        return res;
      } catch (e) {}
      firstClose = str.substr(0, firstClose).lastIndexOf('}');
    } while (firstClose > firstOpen && countClose < 20);
    firstOpen = str.indexOf('{', firstOpen + 1);
  } while (firstOpen != -1 && countOpen < 20);
}
function createDialog() {
  if (qS('#daContainer')) {
    qS('#daContainer').style = '';
    qS('#stopAjaxCkb').checked = false;
    return;
  }
  var d = document.createElement('div');
  var s = document.createElement('style');
  s.textContent = '#daContainer {position: fixed; width: 360px; \
    top: 20%; left: 50%; margin-left: -180px; background: #FFF; \
    padding: 1em; border-radius: 0.5em; line-height: 2em; z-index: 9999;\
    box-shadow: 1px 3px 3px 0 rgba(0,0,0,.2),1px 3px 15px 2px rgba(0,0,0,.2);}\
    #daHeader {font-size: 1.5rem; font-weight: 700; background: #FFF; \
    padding: 1rem 0.5rem; color: rgba(0,0,0,.85); \
    border-bottom: 1px solid rgba(34,36,38,.15);} \
    #daContent {font-size: 1.2em; line-height: 1.4; padding: .5rem;} \
    #daContainer a {cursor: pointer;border: 1px solid black;padding: 10px; \
      display: block;} \
    #stopAjaxCkb {display: inline-block; -webkit-appearance: checkbox; \
    width: auto;}';
  document.head.appendChild(s);
  d.id = 'daContainer';
  d.innerHTML = '<div id="daHeader">DownAlbum</div><div id="daContent">' +
    'Status: <span class="daCounter"></span><br>' +
    '<label>Stop <input id="stopAjaxCkb" type="checkbox"></label>' +
    '<div class="daExtra"></div>' +
    '<a class="daOutput">Output</a><a class="daClose">Close</a></div>';
  document.body.appendChild(d);
  qS('.daClose').addEventListener('click', hideDialog);
  qS('.daOutput').addEventListener('click', output);
}
function hideDialog() {
  qS('#daContainer').style = 'display: none;';
}
function closeDialog() {
  document.body.removeChild(qS('#daContainer'));
}
function output(){
  if(location.href.match(/.*facebook.com/)){
    document.title = document.title.match(/(?:.*\|\|)*(.*)/)[1];
    g.photodata.newL = g.newL;
    g.photodata.newLayout = g.newLayout;
    var p=location.href+'&';
    var isAl = p.match(/media\/set|media|set=a/),
    isPS = p.match(/photos_stream/), isGp = p.match(/group/),
    isPhoto = p.match(/photo/), isSearch = p.match(/search/);
    g.photodata.type = g.isPage ? 'Page' : isAl ? 'Album' : isPS ?
      'PhotoStream': isGp ? 'Group' : isSearch ?
      'Search' : isPhoto ? 'Photo' : '';
    p = qS('#pagelet_timeline_medley_photos a[aria-selected="true"]');
    if (g.newL && p) {
      p = p.getAttribute('aria-controls').match(/.*_(.*)/)[1];
      var tab = p.split(':')[2];
      g.photodata.newL_Type = tab == 4 ? 'TaggedPhotos' : tab == 5 ?
        'AllPhotos' : tab == 70 ? 'UntaggedPhotos' : '';
    }
  }else if(location.href.match(/.*instagram.com/)){
    g.photodata.type = 'Instagram';
    document.title=g.photodata.aName;
  }else if(location.href.match(/twitter.com/)){
    g.photodata.type = 'Twitter';
    document.title=g.photodata.aName;
  }else if(location.href.match(/ask.fm/)){
    g.photodata.type = 'Ask.fm';
    document.title = g.title;
  }else if(location.href.match(/weibo.com/)){
    g.photodata.type = 'Weibo';
    document.title=g.photodata.aName;
  }else if(location.href.match(/pinterest/)){
    g.photodata.type = 'Pinterest';
    document.title=g.photodata.aName;
  }
  var ajaxCkb = qS('#stopAjax');
  if(ajaxCkb)ajaxCkb.parentNode.removeChild(ajaxCkb);
  if(g.photodata.photos.length>1000 && !g.largeAlbum){
    if(confirm('Large amount of photos may crash the browser:\nOK->Use Large Album Optimize Cancel->Continue'))g.photodata.largeAlbum = true;
  }
  try {
    chrome.runtime.sendMessage({type:'export',data:g.photodata});
  } catch(e) {
    alert('Cannot export photos, trying export by parts.');
    exportByParts();
  }
}
function exportByParts() {
  var temp = {};
  var keys = Object.keys(g.photodata);
  for (var i = 0; i < keys.length; i++) {
    if (keys[i] !== 'photos') {
      temp[keys[i]] = g.photodata[keys[i]];
    }
  }
  while (g.photodata.photos.length) {
    temp.photos = g.photodata.photos.splice(0, 1000);
    chrome.runtime.sendMessage({type: 'export', data: temp, saveOnly: true});
  }
  alert('Go to "View all downloaded albums" in popup to view loaded photos.');
}
function initDataLoaded(fbid) {
  if (g.dataLoaded[fbid] === undefined) {
    g.dataLoaded[fbid] = {};
  }
}
function handleFbAjax(fbid) {
  var d = g.dataLoaded[fbid];
  if (d !== undefined) {
    var photos = g.photodata.photos;
    var i = g.ajaxLoaded;
    if (!photos[i]) {
      return true;
    }
    if (g.urlLoaded[fbid]) {
      photos[i].url = g.urlLoaded[fbid];
      delete g.urlLoaded[fbid];
    }
    if (g.commentsList[fbid]) {
      photos[i].comments = g.commentsList[fbid];
      delete g.commentsList[fbid];
    }
    photos[i].title = d.title;
    photos[i].tag = d.tag;
    photos[i].date = d.date;
    if (d.video) {
      photos[i].videoIdx = g.photodata.videos.length;
      g.photodata.videos.push({
        url: d.video
      });
    }
    delete g.dataLoaded[fbid];
    delete photos[i].ajax;
    if (g.ajaxLoaded + 1 < photos.length) {
      g.ajaxLoaded++;
      g.ajaxRetry = 0;
    }
    return true;
  }
  return false;
}
function handleFbAjaxProfiles(data) {
  var profiles = Object.keys(data.profiles);
  for (var j = 0; j < profiles.length; j++) {
    try {
      var p = data.profiles[profiles[j]];
      g.profilesList[p.id] = {name: p.name, url: p.uri};
    } catch(e) {}
  }
}
function handleFbAjaxComment(data) {
  try {
    var comments = data.comments;
    var commentsList = [data.feedbacktarget.commentcount];
    var fbid = comments[0].ftentidentifier;
    var timeFix = new Date(parseTime(data.servertime)) - new Date();
  } catch(e) {
    console.log('Cannot parse comment');
    return;
  }
  for (j = 0; j < comments.length; j++){
    try {
      var c = comments[j];
      p = g.profilesList[c.author];
      commentsList.push({
        fbid: fbid,
        id: c.legacyid,
        name: p.name,
        url: p.url,
        text: c.body.text,
        date: parseTime(c.timestamp.time)
      });
    } catch(e) {}
  }
  g.commentsList[fbid] = commentsList;
  g.commentsList.count++;
}
function fbAjax(){
  var len=g.photodata.photos.length,i=g.ajaxLoaded;
  var src;
  try{
    src = getFbid(g.photodata.photos[i].href);
  }catch(e){
    if(i + 1 < len){g.ajaxLoaded++; fbAjax();}else{output();}
    return;
  }
  if (handleFbAjax(src)) {
    if(len<50||i%15==0)console.log('Loaded '+(i+1)+' of '+len+'. (cached)');
    g.statusEle.textContent='Loading '+(i+1)+' of '+len+'.';
    if(i+1!=len){document.title="("+(i+1)+"/"+(len)+") ||"+g.photodata.aName;fbAjax();
    }else{output();}
  }else if(!qS('#stopAjaxCkb')||!qS('#stopAjaxCkb').checked){
  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    clearTimeout(g.timeout);
    let r = this.response, targetJS = [], list = [src];
    if (g.isPageVideo) {
      r = JSON.parse(r.slice(9));
      var k = r.jsmods.instances;
      for (var ii = 0; ii < k.length; ii++) {
        if (!k[ii] || !k[ii].length || !k[ii][1] || !k[ii][1].length) {
          continue;
        }
        if (k[ii][1][0] === 'VideoConfig') {
          var inst = k[ii][2][0].videoData[0];
          initDataLoaded(inst.video_id);
          g.dataLoaded[inst.video_id].video = inst.hd_src || inst.sd_src;
        }
      }
      g.cursor = r.payload.cursor;
    } else {
      targetJS = r.split('/*<!-- fetch-stream -->*/');
    }
    for (var k = 0; k < targetJS.length - 1; k++) {
      var t = targetJS[k], content = JSON.parse(t).content;
      if (!content.payload || !content.payload.jsmods || !content.payload.jsmods.require) {
        continue;
      }
      var require=content.payload.jsmods.require;
      if(require&&(content.id=='pagelet_photo_viewer'||require[0][1]=='addPhotoFbids')){list=require[0][3][0];}
      for (var ii = 0; ii < require.length; ii++) {
        if (!require[ii] || !require[ii].length) {
          continue;
        }
        if (require[ii].length > 2 && require[ii][0] == 'UFIController') {
          var inst = require[ii][3];
          if (inst.length && inst[2]) {
            handleFbAjaxProfiles(inst[2]);
          }
        }
      }
      for (var ii = 0; ii < require.length; ii++) {
        if (!require[ii] || !require[ii].length) {
          continue;
        }
        if (require[ii].length > 2 && require[ii][0] == 'UFIController') {
          var inst = require[ii][3];
          if (inst.length && inst[2].comments && inst[2].comments.length) {
            handleFbAjaxComment(inst[2]);
          }
        }
        if (require[ii][1] == 'storeFromData') {
          var image = require[ii][3][0].image;
          if (image) {
            var keys = Object.keys(image);
            for (var j = 0; j < keys.length; j++) {
              var pid = keys[j];
              if (image[pid].url) {
                g.urlLoaded[pid] = image[pid].url;
              }
            }
          }
        }
      }
      if (t.indexOf('fbPhotosPhotoTagboxBase') > 0 ||
        t.indexOf('fbPhotosPhotoCaption') > 0 ||
        t.indexOf('uiContextualLayerParent') > 0) {
        var markup = content.payload.jsmods.markup;
        for (var ii = 0; ii < markup.length; ii++) {
          var test = markup[ii][1].__html;
          var h = document.createElement('div');
          h.innerHTML = unescape(test);
          var box = h.querySelectorAll('.snowliftPayloadRoot');
          if (box.length) {
            for (var kk = 0; kk < box.length; kk++) {
              var c = box[kk].querySelector('.fbPhotosPhotoCaption');
              var b = box[kk].querySelector('.fbPhotosPhotoTagboxes');
              var a = box[kk].querySelector('abbr');
              if (!a) {continue;}

              var s = c.querySelector('.hasCaption');
              s = !s ? '' : s.innerHTML.match(/<br>|<wbr>/) ?
                s.outerHTML.replace(/'/g,'&quot;') : s.textContent;
              var tag = b.querySelector('.tagBox');
              pid = a.parentNode.href.match(/permalink|story_fbid/) ? null :
                getFbid(a.parentNode.href);
              if (!pid) {
                var btn = box[kk].querySelector('.sendButton');
                if (btn) {
                  pid = parseQuery(btn.href).id;
                }
              }
              initDataLoaded(pid);
              g.dataLoaded[pid].tag = !tag ? '' : b.outerHTML;
              g.dataLoaded[pid].title = s;
              g.dataLoaded[pid].date = a ? parseTime(a.dataset.utime) : '';
            }
          }
          // Handle profile / group video cover
          box = h.querySelector('.img');
          if (h.querySelector('video') && box) {
            try {
              var bg = box.style.backgroundImage.slice(5, -2);
              var file = bg.match(/\/(\w+\.jpg)/)[1];
              for (var kk = g.ajaxLoaded; kk < len; kk++) {
                var a = g.photodata.photos[kk];
                if (a.url.indexOf(file) > 0) {
                  a.url = bg;
                  break;
                }
              }
            } catch (e) {}
          }
        }
      }
      // Fallback to old comment
      var instances = content.payload.jsmods.instances;
      for(ii = 0; instances && ii<instances.length; ii++){
        if (!instances[ii] || !instances[ii].length ||
          !instances[ii][1] || !instances[ii][1].length) {
          continue;
        }
        if (instances[ii][1][0] === 'UFIController') {
          inst = instances[ii][2];
          if (inst.length && inst[2].comments && inst[2].comments.length) {
            handleFbAjaxProfiles(inst[2]);
          }
        }
      }
      for(ii = 0; instances && ii<instances.length; ii++){
        if (!instances[ii] || !instances[ii].length ||
          !instances[ii][1] || !instances[ii][1].length) {
          continue;
        }
        if (instances[ii][1][0] === 'UFIController') {
          inst = instances[ii][2];
          if (inst.length && inst[2].comments && inst[2].comments.length) {
            handleFbAjaxComment(inst[2]);
          }
        }
        if (instances[ii][1][0] === 'VideoConfig') {
          inst = instances[ii][2][0].videoData[0];
          initDataLoaded(inst.video_id);
          g.dataLoaded[inst.video_id].video = inst.hd_src || inst.sd_src;
        }
      }
    }
    handleFbAjax(src);
    if(len<50||i%15==0)console.log('Loaded '+(i+1)+' of '+len+'.');
    g.statusEle.textContent = 'Loaded ' + (i+1) + ' of ' + len;
    if(i+1>=len){
      output();
    }else{
      if (i === g.ajaxLoaded) {
        g.ajaxRetry++;
        if (g.isPageVideo) {
          g.photodata.photos[i].ajax = location.origin +
            '/video/channel/view/story/async/' + src + '/?video_ids[0]=' + src;
        }
      }
      if (g.ajaxRetry > 5) {
        if (g.ajaxAutoNext) {
          g.ajaxRetry = 0;
          g.ajaxLoaded++;
        } else {
          var retryReply = prompt('Retried 5 times.\nTry again->OK\n' +
            'Try next photo->Type 1\nAlways try next->Type 2\n' +
            'Output loaded photos->Cancel');
          if (retryReply !== null) {
            g.ajaxRetry = 0;
            if (+retryReply === 2){
              g.ajaxAutoNext = true;
              g.ajaxLoaded++;
            } else {
              g.ajaxLoaded++;
            }
          } else {
            output();
            return;
          }
        }
      }
      document.title="("+(i+1)+"/"+(len)+") ||"+g.photodata.aName;fbAjax();
    }
  };
  xhr.onreadystatechange = function() {
    if (xhr.readyState == 2 && xhr.status != 200) {
      clearTimeout(g.timeout);
      g.ajaxLoaded++;
      fbAjax();
    }
  };
  g.photodata.photos[i].ajax += `&fb_dtsg_ag=${g.fb_dtsg_ag}`;
  if (g.isPageVideo) {
    xhr.open('POST', g.photodata.photos[i].ajax +
      (g.cursor ? '&cursor=' + g.cursor : ''));
  } else {
    xhr.open('GET', g.photodata.photos[i].ajax);
  }
  g.timeout=setTimeout(function(){
    xhr.abort();
    g.ajaxRetry++;
    if(g.ajaxRetry>5){if(confirm('Timeout reached.\nTry again->OK\nOutput loaded photos->Cancel')){g.ajaxRetry=0;fbAjax();}else{output();}}
  },10000);
  var data = null;
  if (g.isPageVideo) {
    if (!g.fb_dtsg) {
      getFbDtsg();
    }
    data = `__user=${g.Env.user}&__a=1&fb_dtsg=${g.fb_dtsg}&fb_dtsg_ag=${g.fb_dtsg_ag}`;
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
  }
  xhr.send(data);}else{output();}
}
function getPhotos(){
  if(g.start!=2||g.start==3){return;}
  var scrollEle = !!(qS('#fbTimelinePhotosScroller *, ' +
    '.uiSimpleScrollingLoadingIndicator, .fbStarGrid~img, ' +
    '.fbStarGridWrapper~img, #browse_result_below_fold, ' +
    '#content_container div > span[aria-busy="true"], ' +
    '#pages_video_hub_all_videos_pagelet .uiMorePagerLoader') ||
    (!qS('#browse_end_of_results_footer') && qS('#content div.hidden_elem')
    && location.href.match('search')));
  if(g.ajaxFailed&&g.mode!=2&&scrollEle){scrollTo(0, document.body.clientHeight);setTimeout(getPhotos,2000);return;}//g.start=3;
  var i, photodata = g.photodata, testNeeded = 0, ajaxNeeded = 0;
  var elms = g.elms || qS('#album_photos_pagelet') || qS('#album_pagelet') ||
    qS('#static_set_pagelet') || qS('#pagelet_photos_stream') ||
    qS('#group_photoset') || qS('#initial_browse_result') ||
    qS('#pagelet_timeline_medley_photos') || qS('#content_container') ||
    qS('#content');
  var grid = qSA('#fbTimelinePhotosFlexgrid, .fbStarGrid, ' +
    '#pages_video_hub_all_videos_pagelet');
  var selector = 'a[rel="theater"]';
  var tmp = [], tmpE, eLen;
  if(g.elms){ajaxNeeded=1;}
  else if(grid.length){
    if(grid.length>1){
      for(eLen = 0; eLen<grid.length; eLen++){
        tmpE = grid[eLen].querySelectorAll(g.thumbSelector);
        for(var tmpLen = 0; tmpLen<tmpE.length; tmpLen++){
          tmp.push(tmpE[tmpLen]);
        }
      }
      elms = tmp; ajaxNeeded=1;
    }else{elms=grid[0].querySelectorAll(g.thumbSelector);ajaxNeeded=1;}
  }else if(elms){
    var temp = elms.querySelectorAll(g.thumbSelector);ajaxNeeded=1;
    if(!temp.length){
      testNeeded = 1;
      tmpE = elms.querySelectorAll(selector);
      for(eLen = 0; eLen < tmpE.length; eLen++){
        if (tmpE[eLen].querySelector('img')) {
          tmp.push(tmpE[eLen]);
        }
      }
      elms = tmp;
    }else{
      elms = temp;
    }
  }
  else{elms=qSA(selector);testNeeded=1;}
  if(qSA('.fbPhotoStarGridElement')){ajaxNeeded=1;}

  if (g.isPage) {
    if (qS('input[type="file"][accept="image/*"]')) {
      g.pageType = 'other';
    } else {
      g.pageType = 'posted';
    }
  }

  if(g.mode!=2&&!g.lastLoaded&&scrollEle&&(!qS('#stopAjaxCkb')||!qS('#stopAjaxCkb').checked)){
    fbAutoLoad(g.isPage && !g.isVideo ? [] : elms);return;
  }
  for (i = 0;i<elms.length;i++) {
    if (testNeeded) {
      var test1 = (getParent(elms[i],'.mainWrapper')&&getParent(elms[i],'.mainWrapper').querySelector('.shareSubtext')&&elms[i].childNodes[0]&&elms[i].childNodes[0].tagName=='IMG');
      var test2 = (getParent(elms[i],'.timelineUnitContainer')&&getParent(elms[i],'.timelineUnitContainer').querySelector('.shareUnit'));
      var test3 = (elms[i].querySelector('img')&&!elms[i].querySelector('img').scrollHeight);
      if (test1 || test2 || test3) {
        continue;
      }
    }
    try{
    var ajaxify = unescape(elms[i].getAttribute('ajaxify')) || '';
    var href = ajaxify.indexOf('fbid=') > -1 ? ajaxify : elms[i].href;
    var isVideo = (href.indexOf('/videos/') > -1 || g.isVideo);
    var parentSrc = elms[i].parentNode ?
      elms[i].parentNode.getAttribute('data-starred-src') : '';
    var bg = !isVideo ? elms[i].querySelector('img, i') :
      elms[i].querySelector(g.isPage ? 'img' : 'div[style], .uiVideoLinkImg');
    var src = bg ? bg.getAttribute('src') : '';
    if (src) {
      if (src.indexOf('rsrc.php') > 0) {
        src = '';
      } else if (src && src.indexOf('?') === -1) {
        src = parseFbSrc(src);
      }
    }
    bg = bg && bg.style ? (bg.style.backgroundImage || '').slice(5, -2) : '';
    var url = src || parentSrc || bg;
    var ohref = href + '';
    var fbid = getFbid(href);
    if(href.match('opaqueCursor')){
      if(fbid){
        href = location.origin + '/photo.php?fbid=' + fbid;
      }else{
        continue;
      }
    }else if(href.match('&')){
      href=href.slice(0, href.indexOf('&'));
    }
    if(!g.downloaded[fbid]){g.downloaded[fbid]=1;}else{continue;}
    var ajax = '';
    if (!g.notLoadCm && !isVideo) {
      var q = {};
      if (url.indexOf('&src') != -1) {
        ajax = url.slice(url.indexOf("?")+1,url.indexOf("&src")).split("&");
        url = parseFbSrc(url.match(/&src.(.*)/)[1]).replace(/&smallsrc=.*\?/, '?', true);
      } else {
        ajax = ohref.slice(ohref.indexOf('?') + 1).split('&');
        var pset = ohref.match(/\/photos\/([\.\d\w-]+)\//);
        if (pset) {
          q = {set: pset[1]};
        }
      }
      for(var j=0;j<ajax.length;j++){var d=ajax[j].split("=");q[d[0]]=d[1];}
      if(!q.fbid && fbid){
        q.fbid = fbid;
      }
      ajax = location.origin + '/ajax/pagelet/generic.php/' +
        'PhotoViewerInitPagelet?ajaxpipe=1&ajaxpipe_fetch_stream=1&ajaxpipe_token=' +
        g.Env.ajaxpipe_token + '&no_script_path=1&data=' + JSON.stringify(q)+
        '&__user=' + g.Env.user + '&__a=1&__adt=2';
    } else if (!g.notLoadCm && isVideo) {
      if (g.isPage) {
        if (i === 0) {
          ajax = location.origin + '/video/channel/view/story/async/' + fbid +
            '/?video_ids[0]=' + fbid;
        } else {
          ajax = location.origin + '/video/channel/view/async/' + g.pageId +
            '/?story_count=20&original_video_id=' +
            getFbid(photodata.photos[photodata.photos.length - 1].href);
        }
      } else {
        var id = href.match(/\/videos\/([\w+\d\.-]+)\/(\d+)/);
        var q = {
          type: 3,
          v: id[2],
          set: id[1]
        };
        ajax = location.origin + '/ajax/pagelet/generic.php/' +
          'PhotoViewerInitPagelet?ajaxpipe=1&ajaxpipe_fetch_stream=1&ajaxpipe_token=' +
          g.Env.ajaxpipe_token + '&no_script_path=1&data=' + JSON.stringify(q) +
          '&__user=' + g.Env.user + '&__a=1&__adt=2';
      }
    }
    if(url.match(/\?/)){
      var b=url.split('?'), t='', a=b[1].split('&');
      for(var ii=0;ii<a.length;ii++){
        if(a[ii].match(/oh|oe|__gda__/))t+=a[ii]+'&';
      }
      url = b[0] + (t.length?('?'+t.slice(0, -1)):'');
    } else if (url.indexOf('&') > 0) {
      url = url.slice(0, url.indexOf('&'));
    }
    var title = elms[i].getAttribute('title') || (elms[i].querySelector('img') ?
      elms[i].querySelector('img').getAttribute('alt') : '') || '';
    title=title.indexOf(' ')>0?title:'';
    title=title.indexOf(': ')>0||title.indexOf('： ')>0?title.slice(title.indexOf(' ')+1):title;
    if(!title){
    t=getParent(elms[i],'.timelineUnitContainer')||getParent(elms[i],'.mainWrapper');
    if(t){var target1=t.querySelectorAll('.fwb').length>1?'':t.querySelector('.userContent');}
    var target2=elms[i].getAttribute('aria-label')||'';
    if(target2){title=target2;}
    if(title===''&&target1){title=target1.innerHTML.match(/<br>|<wbr>/)?target1.outerHTML.replace(/'/g,'&quot;'):target1.textContent;}
    }
    var newPhoto={url: url, href: href};
    newPhoto.title=title;
    if (elms[i].dataset.date) {
      newPhoto.date = parseTime(elms[i].dataset.date);
    }
    if(!g.notLoadCm)newPhoto.ajax=ajax;
    if (url) {
      photodata.photos.push(newPhoto);
    }
    }catch(e){console.log(e);}
  }
  /*if(g.store){
    var temp=escape(JSON.stringify(photodata));
    console.log('sent to bg');
    chrome.extension.sendRequest({type:'store',data:temp,no:photodata.photos.length,add:(g.mode==4||g.mode==3)});
    if(g.mode!=4){
    window.alert('Please go to next page.');
    }else{setTimeout(function(){chrome.extension.sendRequest({type:'export'});},1000);}
  }else{*/
    if(qS('#stopAjaxCkb')&&qS('#stopAjaxCkb').checked){qS('#stopAjaxCkb').checked=false;}
    console.log('export '+photodata.photos.length+' photos.');
    if(!g.notLoadCm){
      if (ajaxNeeded && (g.loadCm || confirm("Try to load photo's caption?"))) {
        g.elms = null;
        fbAjax();
      } else {output();}
    }else{output();}
  //}
}
function getFbMessagesPhotos() {
  if (!g.threadId) {
    g.ajax = null;
    g.photodata.aName = getText('.fb_content [role="main"] h2');
    if (qS('a[uid]')) {
      g.threadId = qS('a[uid]').getAttribute('uid');
    } else if (location.href.match(/messages\/t\/(\d+)/)) {
      g.threadId = location.href.match(/messages\/t\/(\d+)/)[1];
    } else {
      alert('Cannot get message thread id.');
      return;
    }
  }
  var variables = JSON.stringify({ id: g.threadId, first: 30, after: g.ajax });
  var url = location.origin + '/webgraphql/query/?query_id=515216185516880&variables='+variables;
  var data = '__user='+g.Env.user+'&__a=1&__req=7&fb_dtsg='+g.fb_dtsg;
  var xhr = new XMLHttpRequest();
  xhr.onload = function(){
    var payload = extractJSON(this.response).payload[g.threadId];
    if (!payload.message_shared_media) {
      alert('Cannot get message media.');
      return;
    }
    for (var i = 0; i < payload.message_shared_media.edges.length; i++) {
      var n = payload.message_shared_media.edges[i].node;
      g.photodata.photos.push({ href: '', url: n.image2.uri });
    }
    g.statusEle.textContent = 'Loading album... (' + g.photodata.photos.length + ')';
    if (payload.message_shared_media.page_info.has_next_page) {
      g.ajax = payload.message_shared_media.page_info.end_cursor;
      getFbMessagesPhotos();
    } else if (g.photodata.photos.length) {
      output();
    }
  };
  xhr.open('POST', url);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send(data);
}
function getQL(type, target, key) {
  if (g.pageType === 'album') {
    if (!g.elms.length && !g.ajaxStartFrom) {
      return 'Query PhotoAlbumRoute {node(' + g.pageAlbumId +
        ') {id,__typename,@F8}} QueryFragment F0 : Photo {album {' +
        'album_type,id},can_viewer_edit,id,owner {id,__typename}} ' +
        'QueryFragment F1 : Photo {can_viewer_delete,id} QueryFragment F2 : ' +
        'Feedback {does_viewer_like,id} QueryFragment F3 : Photo {id,album {' +
        'id,name},feedback {id,can_viewer_comment,can_viewer_like,likers {' +
        'count},comments {count},@F2}} QueryFragment F4 : Photo {' +
        'can_viewer_edit,id,image as _image1LP0rd {uri},url,modified_time,' +
        'message {text},@F0,@F1,@F3} QueryFragment F5 : Node {id,__typename}' +
        ' QueryFragment F6 : Album {can_upload,id} QueryFragment F7 : Album' +
        ' {id,media.first(28) as ' + key + ' {edges {node {__typename,@F4,' +
        '@F5},cursor},page_info {has_next_page,has_previous_page}},owner {' +
        'id,__typename},@F6} QueryFragment F8 : Album {can_edit_caption,' +
        'can_upload,id,media.first(28) as ' + key + ' {edges {node {' +
        '__typename,@F4,@F5},cursor},page_info {has_next_page,' +
        'has_previous_page}},message {text},modified_time,owner {' +
        'id,name,__typename},@F6,@F7}';
    }
    return 'Query ' + type + ' {node('+ g.pageAlbumId +
      ') {@F6}} QueryFragment F0 : Photo {album {album_type,id},' +
      'can_viewer_edit,id,owner {id,__typename}} QueryFragment F1 : ' +
      'Photo {can_viewer_delete,id} QueryFragment F2 : Feedback ' +
      '{does_viewer_like,id} QueryFragment F3 : Photo {id,album {id,name},' +
      'feedback {id,can_viewer_comment,can_viewer_like,likers {count},' +
      'comments {count},@F2}} QueryFragment F4 : Photo {can_viewer_edit,id,' +
      'image as _image1LP0rd {uri},url,modified_time,message {text},' +
      '@F0,@F1,@F3} QueryFragment F5 : Node ' +
      '{id,__typename} QueryFragment F6 : ' + target +
      '.first(28) as ' + key +' {edges {node {__typename,@F4,@F5},cursor},' +
      'page_info {has_next_page,has_previous_page}}}';
  } else {
    if (g.pageType === 'other' && !g.elms.length && !g.ajaxStartFrom) {
      return 'Query MediaPageRoute {node(' + g.pageId + ') {id,__typename,' +
        '@F5}} QueryFragment F0 : Photo {album {album_type,id},' +
        'can_viewer_edit,id,owner {id,__typename}} QueryFragment F1 : ' +
        'Photo {can_viewer_delete,id} QueryFragment F2 : Feedback {' +
        'does_viewer_like,id} QueryFragment F3 : Photo {id,album {id,name}' +
        ',feedback {id,can_viewer_comment,can_viewer_like,likers {count},' +
        'comments {count},@F2}} QueryFragment F4 : Photo {can_viewer_edit,' +
        'id,image as _image1LP0rd {uri},url,modified_time,message {text},' +
        '@F0,@F1,@F3} QueryFragment F5 : Page {id,photos_by_others.first(28)' +
        ' as _photos_by_others4vtdVT {count,edges {node {id,@F4},cursor}, ' +
        'page_info {has_next_page,has_previous_page}}}';
    }
    return 'Query ' + type + ' {node(' + g.pageId +
      ') {@F3}} QueryFragment F0 : Feedback {does_viewer_like,id} ' +
      'QueryFragment F1 : Photo {id,album {id,name},feedback ' +
      '{id,can_viewer_comment,can_viewer_like,likers {count},' +
      'comments {count},@F0}} QueryFragment F2 : Photo {image' +
      ' as _image1LP0rd {uri},url,id,modified_time,message {text},@F1} ' +
      'QueryFragment F3 : ' + target + '.first(28) as ' + key + ' {edges {' +
      'node {id,@F2},cursor},page_info {has_next_page,has_previous_page}}}';
  }
}
function fbLoadPage() {
  var xhr = new XMLHttpRequest();
  var docId, key, type;
  switch (g.pageType) {
    case 'album':
      docId = '2101400366588328';
      key = 'media';
      type = 'PagePhotosTabAlbumPhotosGridPaginationQuery';
      break;
    case 'other':
      docId = '2064054117024427';
      key = 'photos_by_others';
      type = 'PagePhotosTabPostByOthersPhotoGridsRelayModernPaginationQuery';
      break;
    case 'posted':
    default:
      docId = '1887586514672506';
      key = 'posted_photos';
      type = 'PagePhotosTabAllPhotosGridPaginationQuery';
  }
  xhr.onload = function() {
    var r = extractJSON(this.responseText);
    var d = (r.data.page || r.data.album)[key];
    var images = d.edges, img, e = [];
    var doc = document.createElement('div');
    for (var i = 0; i < images.length; i++) {
      img = images[i].node;
      doc.innerHTML = '<a href="' + img.url + '" rel="theater"><img src="' +
        img.image.uri + '" alt=""></a>';
      e.push(doc.childNodes[0].cloneNode(true));
      g.last_fbid = img.id;
    }
    g.elms = g.elms.concat(e);
    if (g.pageType === 'album' && images.length) {
      g.photodata.aName = images[0].node.album.name;
    }

    g.statusEle.textContent = 'Loading album... (' + g.elms.length + ')';
    document.title = '(' + g.elms.length + ') ||' + g.photodata.aName;

    if (d.page_info && d.page_info.has_next_page && !qS('#stopAjaxCkb').checked) {
      g.cursor = d.page_info.end_cursor;
      setTimeout(fbLoadPage, 1000);
    } else {
      console.log('Loaded ' + g.elms.length + ' photos.');
      g.lastLoaded = 1;
      setTimeout(getPhotos, 1000);
    }
  }
  xhr.open('POST', location.origin + '/api/graphql/');
  xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
  var variables = '{"count":28,"cursor":"' + (g.cursor || '') + '","' +
    (g.pageAlbumId ? ('albumID":"' + g.pageAlbumId) : ('pageID":"' + g.pageId)) + '"}';
  var data = '__user=' + g.Env.user + '&fb_dtsg=' + g.fb_dtsg + 
    '&variables=' + variables + '&doc_id='+ docId;
  xhr.send(data);
}
function getFbDtsg() {
  var s = qSA('script');
  for (var i = 0; i < s.length; i++) {
    if (s[i].textContent.indexOf('DTSGInitialData') > 0) {
      s = s[i].textContent;
      break;
    }
  }
  let dtsg = s.slice(s.indexOf('DTSGInitialData'));
  dtsg = dtsg.slice(0, dtsg.indexOf('}')).split('"');
  if (!dtsg.length || !dtsg[4]) {
    fbAutoLoadFailed();
    return;
  }
  g.fb_dtsg = dtsg[4];
  let token = s.slice(s.indexOf('async_get_token'));
  token = token.slice(0, token.indexOf('}')).split('"');
  g.fb_dtsg_ag = token[2];
}
function fbAutoLoadFailed(){
  if(confirm('Cannot load required variable, refresh page to retry?')){
    location.reload();
  }else{
    g.lastLoaded=1;getPhotos();
  }
}
function fbAutoLoad(elms){
  var l; if(g.ajaxStartFrom){
    elms = [];
    g.elms = [];
    l = g.ajaxStartFrom;
  } else if (elms.length) {
    for (var i = elms.length - 1; i > elms.length - 5 && !l; i--) {
      l = getFbid(elms[i].getAttribute('ajaxify')) || getFbid(elms[i].href);
    }
    if(!l){
      alert("Autoload failed!");g.lastLoaded=1;getPhotos();
      return;
    }
  }
  var ajaxAlbum = '', targetURL, tab, pType;
  if(!g.last_fbid){
    g.last_fbid = l;
  }else if(g.last_fbid==l){
    if(g.ajaxRetry<5 && elms.length > 2){l=elms[elms.length-2].href;l=l.slice(l.indexOf('=')+1,l.indexOf('&'));g.ajaxRetry++;}
    else if(confirm('Reaches end of album / Timeouted.\nTry again->OK\nOutput loaded photos->Cancel')){g.ajaxRetry=0;}else{g.lastLoaded=1;getPhotos();return;}
  }else{
    g.last_fbid=l;
  }
  var p = location.href + '&';
  var isAl = p.match(/media\/set|media|set=a/)
  var aInfo = {};
  var isPS = p.match(/photos_stream/);
  var isGp = p.match(/group/);
  var isGraph = p.match(/search/);
  if (g.isPage && !g.isVideo) {
    if (!g.pageId){
      fbAutoLoadFailed();
      return;
    }
    if (p.match(/album_id=/)) {
      p = qS('.uiMediaThumb, [data-token] a');
      if (!p) {
        return fbAutoLoadFailed();
      }
      p = p.getAttribute('href').match(/a\.[\.\d]+/g);
      g.pageType = 'album';
      g.pageAlbumId = p[p.length - 1].split('.')[1];
    }
    getFbDtsg();
    g.elms = [];
    return fbLoadPage();
  }
  if (g.isPage) {
    if (!g.cursor) {
      var s = qSA('script');
      for (var i = 0; i < s.length; i++) {
        if (s[i].textContent.indexOf('cursor') > 0) {
          s = s[i].textContent;
          break;
        }
      }
      var cursor = null;
      try {
        cursor = extractJSON(s);
        var idx = cursor.jscc_map.indexOf('Pagelet');
        g.cursor = extractJSON(cursor.jscc_map.slice(idx));
      } catch (e) {}
      if (!cursor) {
        return fbAutoLoadFailed();
      }
    }
  } else if (isGp) {
    p = elms[0].href.match(/g\.(\d+)/)[1];
    aInfo = {
      scroll_load: true,
      last_fbid: l,
      fetch_size: 120,
      group_id: p,
      filter: g.isVideo ? 'videos' : 'photos'
    };
  }else if (isAl){
    if (!g.isPage) {
      p = p.match(/set=([\w+\.\d]*)&/) || p;
      p = p.length ? p[1] : p.slice(p.indexOf('=')+1,p.indexOf('&'));
      aInfo={"scroll_load":true,"last_fbid":l,"fetch_size":32,"profile_id":+g.pageId,"viewmode":null,"set":p,"type":"1"};
    }

    var token = qS("div[aria-role='tabpanel']");
    if (token && token.id) {
      token = token.id.split("_")[4];
      var user = token.split(':')[0];
      var tnext = qS('.fbPhotoAlbumTitle').nextSibling;
      var isCollab = tnext && tnext.className != 'fbPhotoAlbumActions' &&
        tnext.querySelectorAll('[data-hovercard]').length > 1;

      if (location.href.match(/collection_token/) || isCollab || g.isVideo) {
        aInfo.collection_token = token;
        aInfo.profile_id = user;
      }
    }
    if (g.isVideo) {
      p = qS('#pagelet_timeline_medley_photos a[aria-selected="true"]');
      var lst = parseQuery(unescape(p.getAttribute('href')).split('?')[1]);
      aInfo.cursor = '0';
      aInfo.tab_key = 'media_set';
      aInfo.type = '2';
      aInfo.lst = lst.lst;
    }
  }else if(isGraph){
    var query = {};
    if(!g.query){
      var s=qSA("script"), temp=[];
      for(var i=0;i<s.length;i++){
        if (s[i].textContent.indexOf('encoded_query') > 0) {
          temp[0] = s[i].textContent;
        }
        if(s[i].textContent.indexOf('cursor:"') > 0) {
          temp[1] = s[i].textContent;
        }
      }
      query = temp[0];
      var cursor = temp[1];
      query = extractJSON(query);
      cursor = extractJSON(cursor);
      if (!query || !cursor) {
        fbAutoLoadFailed();
        return;
      }
      var rq = query.jsmods.require;
      for(i=0; i<rq.length; i++){
        if(rq[i][0] == "BrowseScrollingPager"){
          query = rq[i][3][0].globalData;
          break;
        }
      }
      rq = cursor.jsmods.require;
      for(i=0; i<rq.length; i++){
        if(rq[i][0] == "BrowseScrollingPager"){
          cursor = rq[i][3][0].cursor;
          break;
        }
      }
      query.cursor = cursor;
      query.ads_at_end = false;
      g.query = query;
    }else{
      query = g.query;
      query.cursor = g.cursor;
    }
    aInfo = query;
  }else if(!g.newL){
    var ele = qS('#pagelet_timeline_main_column');
    if (ele) {
      p = JSON.parse(ele.dataset.gt).profile_owner;
    } else if (ele = qS('#pagesHeaderLikeButton [data-profileid]')) {
      p = ele.dataset.profileid;
    } else {
      alert('Cannot get profile id!');
      return;
    }
    aInfo={"scroll_load":true,"last_fbid":l,"fetch_size":32,"profile_id":+p,"tab_key":"photos"+(isPS?'_stream':''),"sk":"photos"+(isPS?'_stream':'')};
  } else if (!ajaxAlbum) {
    p = qS('#pagelet_timeline_medley_photos a[aria-selected="true"]');
    if (!p) {
      return alert('Please go to photos tab or album.');
    }
    var lst = unescape(p.getAttribute('href')).split('?')[1];
    if (!lst) {
      return fbAutoLoadFailed();
    }
    lst = parseQuery(lst);
    p = p.getAttribute('aria-controls').match(/.*_(.*)/)[1];
    var userId = p.match(/(\d*):.*/)[1];
    tab = +p.split(':')[2];
    if(qS('.hidden_elem .fbStarGrid')){
      var t=qS('.hidden_elem .fbStarGrid');t.parentNode.removeChild(t);getPhotos();return;
    }
    if (!g.cursor) {
      var s = qSA('script');
      for (i = 0; i < s.length; i++) {
        if (s[i].textContent.indexOf('MedleyPageletRequestData') > 0) {
          try {
            rq = extractJSON(s[i].textContent).jsmods.require;
            rq.forEach(function(e) {
              if (e && e[0] === 'MedleyPageletRequestData') {
                g.pageletToken = e[3][0].pagelet_token;
              }
            })
          } catch (e) {}
        } else if (s[i].textContent.indexOf('enableContentLoader') > 0) {
          try {
            rq = extractJSON(s[i].textContent).jsmods.require;
            rq.forEach(function(e) {
              if (e && e[1] === 'enableContentLoader') {
                g.cursor = e[3][2];
              }
            });
          } catch (e) {}
        }
      }
      if (!g.cursor || !g.pageletToken) {
        alert('Cannot get cursor for auto load!');
      }
    }
    aInfo = {
      collection_token: p,
      cursor: g.cursor,
      disablepager: false, overview: false,
      profile_id: userId,
      pagelet_token: g.pageletToken,
      tab_key: tab === 5 ? 'photos' : 'photos_of',
      lst: lst.lst,
      ftid: null, order: null, sk: 'photos', importer_state: null
    };
  }
  if (g.isPage) {
    ajaxAlbum = location.origin + '/ajax/pagelet/generic.php/' +
      'PagesVideoHubVideoContainerPagelet?data=' +
      escape(JSON.stringify(g.cursor)) + '&__user=' + g.Env.user + '&__a=1';
  } else if (isGraph) {
    ajaxAlbum = location.origin + '/ajax/pagelet/generic.php/' +
      'BrowseScrollingSetPagelet?data=' + escape(JSON.stringify(aInfo)) +
      '&__user=' + g.Env.user + '&__a=1';
  }else if(!g.newL || isGp || isAl){
    targetURL = isGp ? 'GroupPhotoset' : (g.isVideo ? 'TimelinePhotoSet' :
      'TimelinePhotos' + (isAl ? 'Album' : (isPS ? 'Stream' : '')));
    ajaxAlbum = location.origin + '/ajax/pagelet/generic.php/' + targetURL +
      'Pagelet?ajaxpipe=1&ajaxpipe_token=' + g.Env.ajaxpipe_token +
      '&no_script_path=1&data=' + JSON.stringify(aInfo) + '&__user=' +
      g.Env.user + '&__a=1&__adt=2';
  }else{
    var req = 5+(qSA('.fbStarGrid>div').length-8)/8*2
    tab=qSA('#pagelet_timeline_medley_photos a[role="tab"]');
    pType = +p.split(':')[2];
    targetURL = "";
    switch(pType){
      case 4: targetURL = 'TaggedPhotosAppCollection'; break;
      case 5: targetURL = 'AllPhotosAppCollection'; break;
      case 70: targetURL = "UntaggedPhotosAppCollection";
      cursor = btoa('0:not_structured:'+l);
      aInfo = {"collection_token": p, "cursor": cursor, "tab_key": "photos_untagged","profile_id": +userId,"overview":false,"ftid":null,"sk":"photos"}; break;
    }
    ajaxAlbum = location.origin + '/ajax/pagelet/generic.php/' + targetURL+
      'Pagelet?data=' + escape(JSON.stringify(aInfo)) + '&__user=' +
      g.Env.user+'&__a=1';
  }
  var xhr = new XMLHttpRequest();
  xhr.onload = function(){
    clearTimeout( g.timeout );
    if(this.status!=200){
      if(!confirm('Autoload failed.\nTry again->OK\nOutput loaded photos->Cancel')){g.lastLoaded=1;}getPhotos();return;
    }
    var r=this.response,htmlBase=document.createElement('html');
    var newL = r.indexOf('for')==0;

    var eCount = 0, e, old;
    if(!newL){
      htmlBase.innerHTML=r.slice(6,-7);
      var targetJS=htmlBase.querySelectorAll('script');
      for(var k=0;!newL && k<targetJS.length;k++){
        var t=targetJS[k].textContent,content=t.slice(t.indexOf(', {')+2,t.indexOf('}, true);}')+1);
        if(!content.length||t.indexOf('JSONPTransport')<0){continue;}
        content=JSON.parse(content);
        var d=document.createElement('div');
        d.innerHTML=content.payload.content.content;
        e=d.querySelectorAll(g.thumbSelector);
        if(!e||!e.length)continue;
        eCount+=e.length;
        old=elms?Array.prototype.slice.call(elms,0):'';
        g.elms=old?old.concat(Array.prototype.slice.call(e,0)):e;
      }
    }else{
      r = JSON.parse(r.slice(9));
      htmlBase.innerHTML = r.payload;
      var e = [], temp = [];
      if(g.query){
        temp = htmlBase.querySelectorAll('a[rel="theater"]');
        for(k = 0; k < temp.length; k++){
          if (temp[k].querySelector('img')) {
            e.push(temp[k]);
          }
        }
        temp = [];
        if(e.length)g.cursor = parseQuery(e[e.length-1].href).opaqueCursor;
      }else{
        e = htmlBase.querySelectorAll(g.thumbSelector);
        if (g.pageletToken) {
          g.cursor = '';
          r.jsmods.require.forEach(function(e) {
            if (e && e[1] === 'enableContentLoader') {
              g.cursor = e[3][2];
            }
          });
          if (!g.cursor) {
            g.lastLoaded = 1;
          }
        }
      }
      var map = {};
      for (k = 0; k < e.length; k++) {
        var href = unescape(e[k].getAttribute('ajaxify')) || e[k].href;
        if (!map[href]) {
          map[href] = 1;
          temp.push(e[k]);
        }
      }
      e = temp;
      eCount+=e.length;
      old=elms?Array.prototype.slice.call(elms,0):'';
      g.elms=old?old.concat(Array.prototype.slice.call(e,0)):e;
    }
    if (g.isPage) {
      if (r.jscc_map) {
        g.cursor = extractJSON(r.jscc_map.slice(r.jscc_map.indexOf('Pagelet')));
      } else {
        g.lastLoaded = 1;
        g.cursor = '';
      }
    }
    g.statusEle.textContent = 'Loading album... (' + g.elms.length + ')';
    document.title='('+g.elms.length+') ||'+g.photodata.aName;

    if(!eCount){console.log('Loaded '+g.elms.length+' photos.');g.lastLoaded=1;}
    if (g.ajaxStartFrom) {
      g.ajaxStartFrom = false;
    }
    setTimeout(getPhotos,1000);
  };
  ajaxAlbum += `&fb_dtsg_ag=${g.fb_dtsg_ag}`;
  xhr.open("GET", ajaxAlbum);
  g.timeout=setTimeout(function(){
    xhr.abort();
    if(g.ajaxRetry>5){if(confirm('Timeout reached.\nTry again->OK\nOutput loaded photos->Cancel')){g.ajaxRetry=0;}else{g.lastLoaded=1;}}getPhotos();
  },10000);
  xhr.send();
}
function getAlbums(){
  var k=qSA(".uiMediaThumbAlb");
  for(var i=0,t;t=k[i];++i){
    t.parentNode.innerHTML='<input class="albSelect'+i+'" type="checkbox" />'+t.parentNode.innerHTML
  }
}
function _instaQueryAdd(elms) {
  for (var i = 0; i < elms.length; i++) {
    var feed = elms[i];
    if (!elms || g.downloaded[feed.id]) {
      continue;
    } else {
      g.downloaded[feed.id] = 1;
    }
    var c = feed.edge_media_to_comment || {count: 0};
    var cList = [c.count];
    for (var k = 0; c.edges && k < c.edges.length; k++) {
      var p = c.edges[k].node;
      cList.push({
        name: p.owner.username,
        url: 'http://instagram.com/' + p.owner.username,
        text: p.text,
        date: parseTime(p.created_at)
      });
    }
    var url;
    var isAlbum = feed.__typename === 'GraphSidecar';
    var edges = !isAlbum ? [feed] : feed.edge_sidecar_to_children.edges;
    for (var j = 0; j < edges.length; j++) {
      var n = !isAlbum ? edges[j] : edges[j].node;
      url = parseFbSrc(n.display_url || n.display_src);
      var caption = feed.edge_media_to_caption;
      if (caption) {
        caption = caption.edges.length ? caption.edges[0].node.text : '';
      }
      var tags = n.edge_media_to_tagged_user;
      var tagHtml = '';
      if (tags && tags.edges && tags.edges.length) {
        tagHtml = '<div class="fbPhotosPhotoTagboxes"><div class="tagsWrapper">';
        for (k = 0; k < tags.edges.length; k++) {
          var node = tags.edges[k].node;
          var username = node.user.username;
          tagHtml += '<a target="_blank" href="https://instagram.com/' + username +
            '"><div class="fbPhotosPhotoTagboxBase tagBox igTag" style="left:' +
            parsePos(node.x) +'%;top:' + parsePos(node.y) +
            '%"><div class="tag"><div class="tagPointer">' +
            '<i class="tagArrow "></i><div class="tagName"><span>' + username +
            '</span></div></div></div></div></a>';
        }
        tagHtml += '</div></div>';
      }
      var date = feed.date || feed.taken_at_timestamp;
      const p = {
        title: j === 0 && caption ? caption : (feed.caption || ''),
        url: url,
        href: `https://www.instagram.com/p/${feed.shortcode}/`,
        date: date ? parseTime(date) : '',
        comments: c.count && j === 0 && cList.length > 1 ? cList : '',
        tag: tagHtml
      };
      if (n.is_video) {
        p.videoIdx = g.photodata.videos.length;
        g.photodata.videos.push({
          url: n.video_url,
          thumb: url
        });
      }
      g.photodata.photos.push(p);
    }
  }
}
function _instaQueryProcess(elms) {
  for (var i = 0; i < elms.length; i++) {
    if (elms[i].node) {
      elms[i] = elms[i].node;
    }
    var feed = elms[i];
    if (!elms[i] || (g.downloaded && g.downloaded[feed.id])) {
      continue;
    }
    if (feed.__typename === 'GraphSidecar' || feed.__typename === 'GraphVideo') {
      var albumHasVideo = feed.edge_sidecar_to_children &&
        feed.edge_sidecar_to_children.edges
        .filter(e => e.node.is_video && !e.node.video_url).length;
      if (g.skipAlbum) {
        elms[i] = null;
        continue;
      } else if (albumHasVideo && !feed.video_url) {
        var xhr = new XMLHttpRequest();
        xhr.onload = function() {
          try {
            var data = JSON.parse(this.response);
            elms[i] = data.graphql.shortcode_media;
          } catch (e) {
            elms[i] = null;
          }
          setTimeout(function() {
            _instaQueryProcess(elms);
          }, 500);
        };
        var code = feed.shortcode || feed.code;
        xhr.open('GET', 'https://www.instagram.com/p/' + code + '/?__a=1');
        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
        xhr.setRequestHeader('X-Instagram-GIS', md5(g.rhx_gis + ':/p/' + code + '/'));
        xhr.send();
        return;
      }
    }
  }
  _instaQueryAdd(elms);
  var total = g.total;
  var photodata = g.photodata;
  console.log('Loaded '+photodata.photos.length+' of '+total+' photos.');
  g.statusEle.textContent = 'Loaded ' + photodata.photos.length + ' / '+ total;
  document.title="("+photodata.photos.length+"/"+total+") ||"+photodata.aName;
  if (qS('#stopAjaxCkb') && qS('#stopAjaxCkb').checked) {
    output();
  } else if (g.ajax && +g.mode !== 2) {
    setTimeout(instaQuery, 1000);
  } else {
    output();
  }
}
function instaQuery() {
  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    if (xhr.status === 429) {
      alert('Too many request, Please try again later.');
      if (!qS('.daExtra').innerHTML) {
        qS('.daExtra').innerHTML = '<a class="daContinue">Continue</a>';
        qS('.daContinue').addEventListener('click', instaQuery);
      }
      return;
    }
    if (this.response[0] == '<') {
      if (confirm('Cannot load comments, continue?')) {
        g.loadCm = false;
        instaQuery();
      }
      return;
    }
    var res = JSON.parse(this.response).data.user
    res = g.isTagged ? res.edge_user_to_photos_of_you : res.edge_owner_to_timeline_media;
    g.ajax = res.page_info.has_next_page ? res.page_info.end_cursor : null;
    _instaQueryProcess(res.edges);
  };
  var variables = JSON.stringify({ id: g.Env.user.id, first: 30, after: g.ajax });
  xhr.open('GET', 'https://www.instagram.com/graphql/query/?' +
    'query_hash=' + g.queryHash + '&variables=' + variables);
  xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
  xhr.setRequestHeader('X-Instagram-GIS', md5(g.rhx_gis + ':' + variables));
  xhr.send();
}
function getInstagramQueryId() {
  const s = qS('script[src*="ProfilePageContainer"], script[src*="Commons"]');
  const xhr = new XMLHttpRequest();
  xhr.onload = function() {
    const src = this.response.replace(/void 0/g, '');
    const regex = new RegExp(`${g.isTagged ? 'taggedPosts' : 'profilePosts'}\\S+queryId:"(\\S+)"`)
    let id = src.match(regex);
    if (id) {
      g.queryHash = id[1];
    } else {
      alert('Cannot get query id, using fallback instead');
      g.queryHash = g.isTagged ? 'de71ba2f35e0b59023504cfeb5b9857e' : 'a5164aed103f24b03e7b7747a2d94e3c';
    }
    if (g.isTagged) {
      g.ajax = '';
      return instaQuery();
    }
    getInstagram();
  };
  xhr.open('GET', s.src);
  xhr.send();
}
function getInstagram() {
  if (g.start != 2 || g.start == 3) {
    return;
  }
  g.start = 3;
  if (g.Env.user.biography !== undefined) {
    if (!g.Env.media) {
      closeDialog();
      return alert('Cannot download private account.');
    }
    var res = g.Env.media;
    g.ajax = res.page_info.has_next_page ? res.page_info.end_cursor : null;
    _instaQueryProcess(res.edges);
  }
}
function getFlickr(){
  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    if(this.status!=200){
      console.log(this);return;
    }
    var r=this.response, d=JSON.parse(r.slice(14,-1)), p=d.photoset.photo, len=p.length;
    //console.log(d);
    // todo: add handle for pages > 1
    for(var i=0, k=p[i] ; i<len ; i++, k=p[i]){
      g.photodata.photos.push({
        title: '',
        url: k.url_o,
        href: g.linkPrefix+k.id,
        date: k.datetaken||k.dateupload
      });
    }
    output();
  };
  // Need a api key from page or own(may be risky)
  xhr.open('GET','http://www.flickr.com/services/rest/?format=json&api_key=086959117ee519c56c2d062b57a2f909&photoset_id='+location.href.match(/\/sets\/(.*)\//)[1]+'&extras=url_o%2Cdate_upload%2Cdate_taken&method=flickr.photosets.getPhotos');
  xhr.send();
}
function getWeibo() {
  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    g.ajaxPage++;
    var html = getDOM(JSON.parse(this.response).data);
    var loading = html.querySelector('[node-type="loading"]').getAttribute('action-data');
    g.ajax = parseQuery(loading).since_id;
    var links = html.querySelectorAll("a.ph_ar_box");
    var img = html.querySelectorAll("img.photo_pict");
    for(var imgCount = 0; imgCount < links.length; imgCount++){
      var data = parseQuery(links[imgCount].getAttribute("action-data"));
      var url = img[imgCount].src.match(/:\/\/([\w\.]+)\//);
      url = 'https://' + url[1] + '/large/' + data.pid + '.jpg';
      if(!g.downloaded[url]){g.downloaded[url]=1;}else{continue;}
      // For href since pid !== photo_id therefore cannot use direct link
      g.photodata.photos.push({
        title: '',
        url: url,
        href: `http://photo.weibo.com/${g.uId}/wbphotos/large/mid/${data.mid}/pid/${data.pid}`,
        date: ''
      });
    }
    const count = g.photodata.photos.length;
    console.log(`Loaded ${count} photos.`);
    document.title=`(${count}) ||${g.photodata.aName}`;
    g.statusEle.textContent = `Loaded ${count}`;
    if(qS('#stopAjaxCkb')&&qS('#stopAjaxCkb').checked){output();}
    else if(g.ajax){setTimeout(getWeibo, 2000);}else{output();}
  };
  xhr.open('GET', `https://www.weibo.com/p/aj/album/loading?owner_uid=${g.uId}&` +
    `page_id=${g.pageId}&page=${g.ajaxPage}&ajax_call=1&since_id=${g.ajax}`);
  xhr.send();
}
function getWeiboAlbum() {
  chrome.runtime.sendMessage({ type: 'getWeiboAlbumList', uId: g.uId }, (res) => {
    try {
      const list = res.data.album_list;
      g.statusEle.innerHTML = '<p>Select album to download:</p>'
      for (let i = 0; i < list.length; i++) {
        const a = document.createElement('a');
        const count = list[i].count.photos;
        a.textContent = `${list[i].caption} (${count} photos)`;
        a.addEventListener('click', () => {
          g.aId = list[i].album_id;
          g.photodata.aName = list[i].caption;
          g.total = count;
          loadWeiboAlbum();
        });
        g.statusEle.appendChild(a);
      }
    } catch (e) {
      console.error(e);
      alert('Cannot get album list, try old method instead.');
      getWeibo();
    }
  });
}
function loadWeiboAlbum() {
  chrome.runtime.sendMessage({ type: 'getWeiboAlbum', uId: g.uId, aId: g.aId, ajaxPage: g.ajaxPage }, (res) => {
    g.ajaxPage++;
    let ended = false;
    try {
      const list = res.data.photo_list;
      ended = list.length === 0;
      if (ended) {
        alert('Reached end of album due to author setting.');
      }
      let lastCaption = '';
      for (let i = 0; i < list.length; i++) {
        const e = list[i];
        const url = `${e.pic_host}/large/${e.pic_name}`;
        if (!g.downloaded[url]) { g.downloaded[url] = 1; } else { continue; }
        g.photodata.photos.push({
          title: e.caption == lastCaption ? '' : e.caption,
          url: url,
          href: `https://photo.weibo.com/${g.uId}/talbum/detail/photo_id/${e.photo_id}`,
          date: parseTime(e.timestamp)
        });
        lastCaption = e.caption;
      }
      const count = g.photodata.photos.length;
      console.log(`Loaded ${count} photos.`);
      document.title=`(${count}/${g.total}) ||${g.photodata.aName}`;
      g.statusEle.textContent = `Loaded ${count}/${g.total}`;
      if (qS('#stopAjaxCkb') && qS('#stopAjaxCkb').checked || ended) {
        output();
      } else if (count < g.total) {
        setTimeout(loadWeiboAlbum, 2000);
      } else {
        output();
      }
    } catch (e) {
      console.error(e);
      alert('Cannot get album photos, try old method instead.');
      getWeibo();
    }
  });
}

function getTwitter() {
  chrome.runtime.sendMessage({ type: 'getTwitter',
    id: g.id, ajax: g.ajax, token: g.token, csrf: g.csrf }, (r) => {
    if (r.errors && r.errors.length) {
      alert(r.errors[0].code === 353 ? 'Incognito mode is not supported' :
        'Error when load tweets:' + r.errors[0].message);
      return;
    }
    const photodata = g.photodata;
    let keys = Object.keys(r.globalObjects.tweets);
    keys.sort((a, b) => (+b - +a));
    if (g.photodata.aAuth === null) {
      const user = r.globalObjects.users[g.id];
      photodata.aName = user.screen_name;
      photodata.aAuth = user.name;
      photodata.aDes = user.description;
      g.total = user.media_count;
      g.aTime = parseTime(new Date(r.globalObjects.tweets[keys[0]].created_at), true);
    }
    for (let k = 0; k < keys.length; k++) {
      const t = r.globalObjects.tweets[keys[k]];
      if (!t.extended_entities) {
        continue;
      }
      const media = t.extended_entities.media;
      for (let i = 0; i < media.length; i++) {
        const m = media[i];
        const p = {
          title: i === 0 ? t.text : '',
          url: m.media_url_https + ':orig',
          href: 'https://' + m.display_url,
          date: parseTime(new Date(t.created_at), true)
        };
        if (m.type === 'video') {
          p.videoIdx = photodata.videos.length;
          m.video_info.variants.sort((a, b) => ((b.bitrate || 0) - (a.bitrate || 0)));
          photodata.videos.push({
            url: m.video_info.variants[0].url,
            thumb: m.media_url_https
          });
        }
        photodata.photos.push(p);
      }
    }
    const e = r.timeline.instructions[0].addEntries.entries;
    if (e[e.length - 1].entryId.indexOf('cursor-bottom') > -1) {
      const cursor = e[e.length - 1].content.operation.cursor.value;
      g.ajax = g.ajax === cursor ? false : cursor;
    } else {
      g.ajax = false;
    }
    document.title = `${photodata.photos.length}/${g.total} || ${photodata.aName}`;
    g.statusEle.textContent = photodata.photos.length + '/' + g.total;
    if (qS('#stopAjaxCkb') && qS('#stopAjaxCkb').checked) {
      output();
    } else if (g.ajax) {
      setTimeout(getTwitter, 1000);
    } else {
      output();
    }
  });
}
function getTwitterInit() {
  let r = fetch(qS('link[href*="/main"]').getAttribute('href'))
    .then(r => r.text())
    .then(r => {
      const token = r.match(/="([\w\d]+%3D[\w\d]+)"/g);
      if (!token) {
        alert('Cannot get auth token');
        return;
      }
      g.token = token[0].slice(2, -1);
      getTwitter();
    });
}
function parsePinterest(list){
  var photodata = g.photodata;
  for(var j = 0; j < list.length; j++){
    if (list[j].name || !list[j].images) {
      continue;
    }
    photodata.photos.push({
      title: list[j].description + '<br><a taget="_blank" href="' +
        list[j].link + '">Pinned from ' + list[j].domain + '</a>',
      url: (list[j].images.orig || list[j].images['736x']).url,
      href: 'https://www.pinterest.com/pin/' + list[j].id + '/',
      date: list[j].created_at ? new Date(list[j].created_at).toLocaleString() : false
    });
  }
  console.log('Loaded ' + photodata.photos.length + ' photos.');
}
function getPinterest(){
  var board = location.pathname.match(/([^\/]+)/g);
  if (board && board[0] === 'pin') {
    closeDialog();
    var img = qS('.pinImage, .imageLink img');
    if (img) {
      var link = document.createElement('a');
      link.href = img.getAttribute('src');
      link.download = '';
      link.click();
    }
    return;
  }
  g.source = board ? encodeURIComponent(location.pathname) : '/';
  var s = qS('#initial-state') ? extractJSON(getText('#initial-state')) : null;
  if (!s) {
    var doc = qSA('script');
    for (var i = 0; i < doc.length; i++) {
      var c = doc[i].textContent;
      if (c.indexOf('__INITIAL_STATE__') > 0) {
        s = extractJSON(c.replace(/\\\\\\"/g, '\'').replace(/\\"/g, '"'));
        break;
      }
    }
  }
  if (!s || !s.ui || !s.ui.mainComponent) {
    alert('Cannot load initial state');
    return;
  }
  var type = s.ui.mainComponent.current;
  var resources = s.resources.data;
  while (resources && !resources.data) {
    const key = Object.keys(resources).filter(k => k !== 'UserResource')[0];
    resources = resources[key];
  }
  var r = resources && resources.data ? resources.data : null;
  g.resource = type.replace(/Feed|Page/g, '') + 'FeedResource';
  switch (type) {
    case 'HomePage':
      parsePinterest(r);
      g.bookmarks = {
        bookmarks: [resources.nextBookmark],
        prependPartner: false,
        prependUserNews: false,
        prependExploreRep: null,
        field_set_key: 'hf_grid'
      };
      g.resource = 'UserHomefeedResource';
      break;
    case 'BoardPage':
      g.bookmarks = {
        board_id: r.id,
        board_url: r.url,
        field_set_key: 'react_grid_pin',
        layout: 'default',
        page_size: 25
      };
      break;
    case 'BoardSectionPage':
      g.bookmarks = {
        section_id: r.id,
        page_size: 25
      };
      g.resource = 'BoardSectionPinsResource';
      g.photodata.aName += ' - ' + r.title;
      break;
    case 'DomainFeedPage':
      g.bookmarks = {domain: board[2]};
      break;
    case 'ProfilePage':
      switch (board[2]) {
        case 'pins':
          g.bookmarks = {username: board[1], field_set_key: 'grid_item'};
          g.resource = 'UserPinsResource';
          break;
        case 'likes':
          g.bookmarks = {username: board[1], page_size: 25};
          g.resource = 'UserLikesResource';
          break;
      }
      break;
    case 'SearchPage':
      var query = location.search.slice(1).replace(/&/g, '=').split('=');
      query = query[query.indexOf('q') + 1];
      g.bookmarks = {query: query, scope: board[2]};
      break;
    case 'TopicFeedPage':
      g.bookmarks = {interest: board[2]};
      break;
    case 'InterestFeedPage':
      g.bookmarks = {query: board[2]};
      break;
    default:
      alert('Download type not supported.');
      return;
  }
  if (type === 'SearchPage' || type === 'InterestFeedPage') {
    if (r.results) {
      parsePinterest(r.results);
    }
    if (resources.nextBookmark) {
      g.bookmarks.bookmarks = [resources.nextBookmark];
    }
    g.resource = 'SearchResource';
  }
  getPinterest_sub();
}
function getPinterest_sub(){
  var photodata = g.photodata;
  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    var r = JSON.parse(this.responseText);
    parsePinterest(r.resource_response.data);
    g.bookmarks = r.resource.options;

    document.title="("+g.photodata.photos.length+") ||"+g.photodata.aName;
    g.statusEle.textContent = g.photodata.photos.length + '/' + g.total;
    if(qS('#stopAjaxCkb')&&qS('#stopAjaxCkb').checked){output();}
    else if(g.bookmarks.bookmarks[0] != '-end-'){
      setTimeout(getPinterest_sub, 1000);
    }else{
      output();
    }
  };
  var data = {
    "options" : g.bookmarks,
    "context": {}
  };
  var url = location.origin + '/resource/' + g.resource + '/get/';
  var data = 'source_url=' + g.source + '&data=' +
    escape(JSON.stringify(data)) + '&_=' + (+new Date());
  xhr.open('POST', url);
  xhr.setRequestHeader('Accept', 'application/json, text/javascript, */*; q=0.01');
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  var token = g.token || document.cookie.match(/csrftoken=(\S+);/)
  if(token){
    if(!g.token){
      token = token[1];
      g.token = token;
    }
    xhr.setRequestHeader('X-CSRFToken', token);
    xhr.setRequestHeader('X-NEW-APP', 1);
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.send(data);
  }else{
    alert('Missing token!');
  }
}
function getAskFM() {
  var url = g.page || (location.protocol + '//ask.fm/' + g.username +
    '?no_prev_link=true');
  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    var html = getDOM(this.response);
    var hasMore = html.querySelector('.item-page-next');
    var elms = html.querySelectorAll('.streamItem_visual');
    var i, box, link, title, url, video;
    var photodata = g.photodata;
    for (var i = 0; i < elms.length; i++) {
      box = getParent(elms[i], '.item');
      var img = elms[i].querySelector('img');
      if (!img) {
        continue;
      }
      video = box.querySelector('.playIcon');
      if (video) {
        url = img.getAttribute('src');
        photodata.videos.push({
          url: img.parentNode.getAttribute('href'),
          thumb: url
        });
      } else {
        url = img.parentNode.getAttribute('data-url') ||
          img.getAttribute('src');
      }
      link = box.querySelector('.streamItem_meta');
      var content = box.querySelector('.streamItem_content');
      if (content) {
        content.removeChild(box.querySelector('.readMore'));
      }
      title = 'Q: ' +
        getText('.streamItem_header', 0, box) +
        ' <br>' + 'A: ' + getText('.streamItem_content', 0, box);
      photodata.photos.push({
        title: title,
        url: url,
        href: 'https://ask.fm' + link.getAttribute('href'),
        date: link.getAttribute('title'),
        videoIdx: video ? photodata.videos.length - 1 : undefined
      });
    }
    console.log('Loaded ' + photodata.photos.length + ' photos.');
    g.count += html.querySelectorAll('.item').length;
    g.statusEle.textContent = g.count + '/' + g.total;
    document.title = g.statusEle.textContent + ' ||' + g.title;
    if (g.count < g.total && hasMore && !qS('#stopAjaxCkb').checked) {
      g.page = hasMore.getAttribute('href');
      setTimeout(getAskFM, 500);
    } else {
      if (photodata.photos.length) {
        output();
      } else {
        alert('No photos loaded.');
      }
    }
  };
  xhr.open('GET', url);
  xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
  xhr.send();
}

(function() {
  g.start = 1;
  var pageSetting = qS('#fbDown');
  if(pageSetting){
    var setting = pageSetting.textContent.split(',');
    g.mode = setting[0];
    g.loadCm = (setting[1].length>0);
    g.notLoadCm = !g.loadCm;
    g.largeAlbum = (setting[2].length>0);
    g.newLayout = (setting[3].length>0);
  }
  g.mode = g.mode || window.prompt('Please type your choice:\nNormal: 1/press Enter\nDownload without auto load: 2\nAutoload start from specific id: 3\nOptimization for large album: 4');
  if(g.mode==4){g.largeAlbum=true;g.mode=window.prompt('Please type your choice:\nNormal: 1/press Enter\nDownload without auto load: 2\nAutoload start from specific id: 3');}
  if(g.mode==null){return;}
  if(g.mode==3){g.ajaxStartFrom=window.prompt('Please enter the id:\ni.e. 123456 if photo link is:\nfacebook.com/photo.php?fbid=123456');if(!g.ajaxStartFrom){return;}}
  /*if(g.mode==4){
    var t=qS('#globalContainer');
    var k=document.createElement('div');
    k.id='DownFbDebug';k.style.border='5px red solid';
    url=unescape(qS('a:not(.notifMainLink):not(.hidden_elem):not(.egoPhotoImage):not(.uiBlingBox):not(.tickerFullPhoto)[rel="theater"][ajaxify]').getAttribute('ajaxify'));url.slice(url.indexOf('&src=')+5,url.indexOf('&smallsrc'));
    k.innerHTML='<br><br><br><br>Download FB Album Debug info:<br>'+url+'<br><br><br><a onClick=\'(function(){var t=qS("#DownFbDebug");t.parentNode.removeChild(t);})()\'>Close this</a>';
    t.parentNode.insertBefore(k,t);return;
  }
  if(g.mode==5){try{chrome.extension.sendMessage({type:'export'});}catch(e){chrome.extension.sendRequest({type:'export'});}return;}*/
  /*if(g.get){
  g.last=1;
  chrome.extension.onRequest.addListener(function(a){
    if(!g.photodata){g.start=2;
    g.photodata=JSON.parse(unescape(a));
    console.log(g.photodata.photos.length+' photos got.');
    getPhotos();}
  });
  chrome.extension.sendRequest({type:'get'});
  }else{*/
  var aName=document.title,aAuth="",aDes="",aTime="", s, i, t, env, len;g.start=2;
  g.timeOffset=new Date().getTimezoneOffset()/60*-3600000;
  createDialog();
  g.statusEle = qS('.daCounter');
  if(location.host.match(/.*facebook.com/)){
    if(qS('.fbPhotoAlbumTitle')||qS('.fbxPhotoSetPageHeader')){
    aName = getText('.fbPhotoAlbumTitle') || getText("h2") ||
      getText('span[role="heading"][aria-level="3"]:only-child') || document.title;
    aAuth=getText('#fb-timeline-cover-name')||getText("h2")||getText('.fbStickyHeaderBreadcrumb .uiButtonText')||getText(".fbxPhotoSetPageHeaderByline a");
    if(!aAuth){aName=getText('.fbPhotoAlbumTitle'); aAuth=getText('h2');}
    aDes = getText('.fbPhotoCaptionText', 1) || getText('span[role="heading"][aria-level="4"]');
    try{aTime=qS('#globalContainer abbr').title;
    var aLoc=qS('.fbPhotoAlbumActionList').lastChild;
    if((!aLoc.tagName||aLoc.tagName!='SPAN')&&(!aLoc.childNodes.length||(aLoc.childNodes.length&&aLoc.childNodes[0].tagName!='IMG'))){aLoc=aLoc.outerHTML?" @ "+aLoc.outerHTML:aLoc.textContent;aTime=aTime+aLoc;}}catch(e){}
    }
    if(location.href.match('/search/')){
      var query = qS('input[name="q"][value]');
      aName = query ? query.value : document.title;
    }
    s = qSA("script");
    try{
      for(i=0,t, len = s.length; t=s[i].textContent, i<len; i++){
        if(t.match(/envFlush\({/)){
          g.Env=JSON.parse(t.slice(t.lastIndexOf("envFlush({")+9,-2)); break;
        }
      }
    }catch(e){alert('Cannot load required variable');}
    try{
      for(i=0; t=s[i].textContent, i<len; i++){
        var m = t.match(/"USER_ID":"(\d+)"/);
        if(m){
          g.Env.user = m[1]; break;
        }
      }
    }catch(e){console.warn(e);alert('Cannot load required variable');}
    getFbDtsg();
    if (!g.loadCm) {
      g.loadCm = confirm('Load caption to correct photos url?\n' +
        '(Not required for page)');
      g.notLoadCm = !g.loadCm;
    }
    g.ajaxLoaded=0;g.dataLoaded={};g.ajaxRetry=0;g.ajaxAutoNext=0;g.elms='';g.lastLoaded=0;g.urlLoaded={};
    g.thumbSelector = 'a.uiMediaThumb[ajaxify], a[data-video-id], ' +
      'a.uiMediaThumb[rel="theater"], a.uiMediaThumbMedium, ' +
      '.fbPhotoCurationControlWrapper a[ajaxify][rel="theater"], ' +
      'a.uiVideoLink[ajaxify], ' +
      '#fbTimelinePhotosFlexgrid a[ajaxify]:not(.fbPhotoAlbumAddPhotosButton)';
    g.downloaded={};g.profilesList={};g.commentsList={count:0};
    g.photodata = {
      aName:aName.replace(/'|"/g,'\"'),
      aAuth:aAuth.replace(/'|"/g,'\"'),
      aLink:window.location.href,
      aTime:aTime,
      photos: [],
      videos: [],
      aDes:aDes
    };
    g.newL = !!(qSA('#pagelet_timeline_medley_photos a[role="tab"]').length);
    var xhr = new XMLHttpRequest();
    xhr.onload = function(){
      var html = this.response;
      var doc = getDOM(html);
      var pageId = doc.querySelector('[property="al:ios:url"]');
      var content = pageId ? pageId.getAttribute('content') : '';
      if (pageId && content.match(/page|profile/)) {
        g.isPage = /page/.test(content);
        g.pageId = content.match(/\d+/)[0];
      }
      g.isVideo = location.href.match(/\/videos\/|set=v/);
      g.isPageVideo = g.isPage && g.isVideo;
      if (location.href.match('messages')) {
        g.threadId = 0;
        getFbMessagesPhotos();
      } else {
        getPhotos();
      }
    };
    xhr.open('GET', location.href);
    xhr.send();
  }else if(location.host.match(/.*instagram.com/)){
    if (location.pathname === '/') {
      return alert('Please go to profile page.');
    }
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (this.readyState === 4 && this.status === 429) {
        g.rateLimited = 1;
        alert('Rate limit reached. Please try again later.');
      }
    };
    xhr.onload = function() {
      try {
        g.Env = getSharedData(this.response);
        g.token = g.Env.config.csrf_token;
        g.rhx_gis = g.Env.rhx_gis;
        var data = g.Env.entry_data;
        if (data.ProfilePage) {
          g.Env = data.ProfilePage[0].graphql;
        } else {
          alert('Need to reload for required variable.');
          return location.reload();
        }
      } catch(e) {
        if (g.rateLimited) {
          g.rateLimited = 0;
        } else {
          console.error(e);
          alert('Cannot load required variable!');
        }
        return;
      }
      g.isTagged = location.href.indexOf('/tagged/') > 0;
      g.Env.media = g.isTagged ? { count: 0, edges: [] } :
        g.Env.user.edge_owner_to_timeline_media;
      g.total = g.Env.media.count;
      aName = g.Env.user.full_name || 'Instagram';
      aAuth = g.Env.user.username;
      aLink = g.Env.user.external_url || ('http://instagram.com/'+  aAuth);
      let aTime = 0
      try {
        aTime = g.Env.media && g.Env.media.edges.length ?
          g.Env.media.edges[0].node.taken_at_timestamp : 0;
      } catch (e) {}
      g.photodata = {
        aName: aName.replace(/'|"/g,'\"'),
        aAuth: aAuth,
        aLink: aLink,
        aTime: aTime ? 'Last Update: ' + parseTime(aTime) : '',
        photos: [],
        videos: [],
        aDes: (g.Env.user.bio || g.Env.user.biography || '').replace(/'|"/g,'\"')
      };
      g.downloaded = {};
      getInstagramQueryId();
    };
    xhr.open('GET', location.href);
    xhr.send();
  }else if(location.host.match(/twitter.com/)){
    g.csrf = document.cookie.split(';').filter(s => s.indexOf('ct0') > -1)[0].split('=')[1];
    g.id = qS('img[src*="profile_banners"]') ?
      qS('img[src*="profile_banners"]').getAttribute('src') :
      qS('[data-testid$="follow"]').dataset.testid;
    g.id = g.id.match(/\d+/)[0];
    g.ajax = '';
    g.photodata = {
      aAuth: null,
      aDes: '',
      aLink: location.href,
      aName: '',
      aTime: '',
      photos: [],
      videos: []
    };
    getTwitterInit();
  }else if(location.host.match(/weibo.com/)){
    try{
      aName='微博配圖';
      aAuth=getText('.username') || qS('.pf_photo img') ? qS('.pf_photo img').alt : '';
    }catch(e){}
    g.downloaded = {};
    var k = qSA('script'), id = '';
    for(i=0; i<k.length && !id.length; i++){
      t = k[i].textContent.match(/\$CONFIG\['oid'\]/);
      if(t)id = k[i].textContent;
    }
    eval(id);
    if(!$CONFIG){alert("發生錯誤，請聯絡作者");return;} 
    g.uId = $CONFIG.oid;
    g.pageId = $CONFIG.page_id;
    g.ajaxPage = 1;
    g.ajax = '';
    g.photodata = {
      aName:aName,
      aAuth:aAuth,
      aLink:location.href,
      aTime:aTime,
      photos: [],
      aDes:""
    };
    getWeiboAlbum();
  }else if(location.host.match(/pinterest/)){
    g.photodata = {
      aName: getText('h3, h4') || 'Pinterest',
      aAuth: qS('.profileSource img') ? qS('.profileSource img').alt : '',
      aLink: location.href,
      aTime: aTime,
      photos: [],
      aDes: aDes
    };
    g.total = getText('.belowBoardNameContainer span') || getText('.value') ||
      getText('.fixedHeader+div span');
    getPinterest();
  }else if(location.href.match(/flickr.com/)){
    try{
      aName=qS('h1.set-title').textContent.match(/\s*(.*)\s*/)[1];
      aAuth=qS('#setCrumbs a').textContent;
      aTime=qSA('.vsNumbers')[1].textContent;
    }catch(e){}
    g.linkPrefix=location.href.match(/(.*)sets/)[1];
    g.photodata = {
      aName:aName,
      aAuth:aAuth,
      aLink:location.href,
      aTime:aTime,
      photos: [],
      aDes:""
    };
    getFlickr();
  }else if(location.host.match(/ask.fm/)){
    g.count = 0;
    g.page = 0;
    g.total = +getText('.profileTabAnswerCount');
    g.title = document.title;
    g.username = getText('.profile-name span:nth-of-type(2)').slice(1);
    if (!g.username) {
      g.username = location.href.split('/')[3];
    }
    g.photodata = {
      aName: getText('.profile-name span:nth-of-type(1)'),
      aAuth: g.username,
      aLink: location.href,
      aTime: aTime,
      photos: [],
      videos: [],
      aDes: getText('#sidebarBio', 1)
    };
    getAskFM();
  }
  //}
})();

const base = 'https://www.instagram.com/';
const loadedPosts = {};
const profiles = {};
let fbDtsg = '';
let rhx_gis = '';
let uid = '';

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
function quickSelect(s) {
  var method = false;
  switch (s) {
    case /#\w+$/.test(s):
      method = 'getElementById'; break;
    case /\.\w+$/.test(s):
      method = 'getElementsByClassName'; break;
  }
  return method;
}
function qS(s) { var k = document[quickSelect(s) || 'querySelector'](s); return k && k.length ? k[0] : k;}
function qSA(s) { return document[quickSelect(s) || 'querySelectorAll'](s);}
function padZero(str, len) {
  str = str.toString();
  while (str.length < len) {
    str = '0' + str;
  }
  return str;
}
function parseTime(t){
  var d = new Date(t * 1000);
  return d.getFullYear() + '-' + padZero(d.getMonth() + 1, 2) + '-' +
    padZero(d.getDate(), 2) + ' ' + padZero(d.getHours(), 2) + ':' +
    padZero(d.getMinutes(), 2) + ':' + padZero(d.getSeconds(), 2);
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
    .daCounter {max-height: 300px;overflow-y: auto;} \
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
    '<div class="daExtra"></div><a class="daClose">Close</a></div>';
  document.body.appendChild(d);
  qS('.daClose').addEventListener('click', hideDialog);
}
function hideDialog() {
  qS('#daContainer').style = 'display: none;';
}

if (location.host.match(/instagram.com|facebook.com/)) {
  if (!window.addedObserver) {
    window.addedObserver = true;
    var o = window.WebKitMutationObserver || window.MutationObserver;
    var observer = new o(runLater);
    observer.observe(document.body, {subtree: true, childList: true});
    runLater();
  }
}

function runLater() {
  clearTimeout(window.addLinkTimer);
  window.addLinkTimer = setTimeout(addLink, 300);
}

function addLink() {
  if (location.host.match(/instagram.com/)) {
    if (location.href.indexOf('explore/') > 0) {
      return;
    }
    let k = qSA('article>div:nth-of-type(1), header>div:nth-of-type(1):not([role="button"])');
    for(var i = 0; i<k.length; i++){
      if (k[i].nextElementSibling) {
        _addLink(k[i], k[i].nextElementSibling);
      }
    }
  } else if (location.host.match(/facebook.com/)) {
    addVideoLink();
  }
}

async function _addLink(k, target) {
  var isProfile = (k.tagName == 'HEADER' || k.parentNode.tagName == 'HEADER');
  let username = null;
  if (isProfile) {
    const u = k.parentNode.querySelector('h1, h2, [title]:not(button)');
    if (u) {
      if (u.parentNode.className === 'dLink') {
        return;
      }
      username = u.textContent;
    }
  }
  var tParent = target.parentNode;
  var t = k.querySelector('img, video');
  if (t) {
    var src = t.getAttribute('src');
    if (!src) {
      return setTimeout(addLink, 300);
    }
    src = isProfile && profiles[username] ? profiles[username].src : parseFbSrc(src);
    if (qS('.dLink [href="' + src + '"]')) {
      return;
    }
    var next = isProfile ? target.querySelector('.dLink') :
      target.nextElementSibling;
    if (next) {
      if (next.childNodes[0] &&
        next.childNodes[0].getAttribute('href') == src) {
        return;
      } else {
        (isProfile ? target : tParent).removeChild(next);
      }
    }
  }
  if (isProfile) {
    if (profiles[username] === null) {
      return;
    } else if (profiles[username] === undefined) {
      profiles[username] = null;
      try {
        let r = await fetch(`https://www.instagram.com/${username}/?__a=1`);
        const id = (await r.json()).graphql.user.id;
        r = await new Promise((resolve) => {
          chrome.runtime.sendMessage({ type: 'getIgUserInfo', id }, res => resolve(res));
        });
        profiles[username] = r;
        src = r.src;
      } catch (e) {
        console.error(e);
        profiles[username] = null;
      }
    }
    if (!profiles[username]) {
      return;
    }
    const { id } = profiles[username];
    if (!k.querySelector(`.dStory[data-id="${id}"]`)) {
      const storyBtn = document.createElement('a');
      storyBtn.className = 'dStory';
      storyBtn.style.cssText = 'max-width: 200px; cursor: pointer;';
      storyBtn.dataset.id = id;
      storyBtn.textContent = 'Download Stories';
      k.appendChild(storyBtn);
      storyBtn.addEventListener('click', () => loadStories(id));
      const highlightBtn = document.createElement('a');
      highlightBtn.style.cssText = 'max-width: 200px; cursor: pointer;';
      highlightBtn.textContent = 'Download Highlights';
      k.appendChild(highlightBtn);
      highlightBtn.addEventListener('click', () => loadHighlights(id));
    }
  }
  const container = getParent(k, 'article') || k;
  const albumBtn = container.querySelector('.coreSpriteRightChevron');
  if (t && src) {
    const link = document.createElement('div');
    link.className = 'dLink';
    link.style.maxWidth = '200px';
    const items = [];
    if (albumBtn || (t.getAttribute('poster') && src.indexOf('blob') > -1)) {
      const url = container.querySelector('a time').parentNode.getAttribute('href');
      if (loadedPosts[url] !== undefined) {
        if (loadedPosts[url] === 1) {
          return;
        }
        loadedPosts[url].forEach(img => items.push(img));
      } else {
        loadedPosts[url] = 1;
        let r = await fetch(`${url}?__a=1`, { credentials: 'include' });
        r = await r.json();
        loadedPosts[url] = [];
        const m = r.graphql.shortcode_media;
        (albumBtn ? m.edge_sidecar_to_children.edges : [{ node: m }]).forEach((e, i) => {
          const { dash_info, id, is_video, video_url, display_url } = e.node;
          const dash = is_video && dash_info.is_dash_eligible ? 
            `${id}.mpd,${URL.createObjectURL(new Blob([dash_info.video_dash_manifest]))}|` : '';
          const img = `${dash}${is_video ? `${video_url}|` : ''}${parseFbSrc(display_url)}`;
          loadedPosts[url].push(img);
          items.push(img);
        });
      }
    } else {
      if (src.match('mp4')) {
        src += `|${t.getAttribute('poster')}`;
      }
      items.push(src);
    }
    let html = '';
    items.forEach((e, i) => {
      const s = e.split('|');
      const idx = items.length > 1 ? `#${i + 1} `: '';
      if (s.length > 2) {
        const [name, url] = s.shift().split(',');
        html += `<a href="${url}" download="${name}" target="_blank"\
        >Download ${idx}Video (Dash)</a>`;
      }
      html += s.length > 1 ? `<a href="${s.shift()}" target="_blank"\
        >Download ${idx}Video</a>` : '';
      html += `<a href="${s.shift()}" target="_blank">Download ${idx}Photo</a>`;
    });
    link.innerHTML = html;
    if (isProfile) {
      k.appendChild(link);
    } else if (target.insertAdjacentElement) {
      target.insertAdjacentElement('afterEnd', link);
    } else {
      if (target.nextSibling) {
        tParent.insertBefore(link, target.nextSibling);
      } else {
        tParent.appendChild(link);
      }
    }
  }
}

async function loadStories(id, highlightId = '') {
  const hash = '61e453c4b7d667c6294e71c57afa6e63';
  const variables = `{"reel_ids":["${id}"],"tag_names":[],` +
      `"location_ids":[],"highlight_reel_ids":[${highlightId}],`+
      `"precomposed_overlay":false,"show_story_header_follow_button":false}`;
  try {
    const url = `${base}graphql/query/?query_hash=${hash}&variables=${variables}`;
    let r = await fetch(url, { credentials: 'include' });
    r = await r.json();
    if (!r.data.reels_media || !r.data.reels_media.length) {
      alert('No stories loaded');
      return;
    }
    const type = highlightId !== '' ? 'GraphHighlightReel' : 'GraphReel';
    const { items, latest_reel_media: last, owner, user } =
      r.data.reels_media.filter(e => e.__typename === type)[0];
    const lastTime = last ? last : items[0].taken_at_timestamp;
    const photodata = {
      aDes: '',
      aName: 'Stories',
      aAuth: (user || owner).username,
      aLink: `${base}${(user || owner).username}`,
      aTime: lastTime ? 'Last Update: ' + parseTime(lastTime) : '',
      newL: true,
      newLayout: true,
      photos: [],
      videos: [],
      type: 'Stories',
    };
    items.forEach((e, i) => {
      const p = { url: e.display_url, href: '',
        date: parseTime(e.taken_at_timestamp) };
      if (e.video_resources) {
        p.videoIdx = photodata.videos.length;
        const { src } = e.video_resources[e.video_resources.length - 1];
        photodata.videos.push({ url: src, thumb: e.display_url });
      }
      photodata.photos.push(p);
    });
    chrome.runtime.sendMessage({ type:'export', data: photodata });
  } catch (e) {
    console.error(e);
    alert('Cannot load stories');
  }
}
async function loadHighlights(id) {
  const hash = 'ad99dd9d3646cc3c0dda65debcd266a7';
  const variables = `{"user_id":"${id}","include_highlight_reels":true}`;
  try {
    const url = `${base}graphql/query/?query_hash=${hash}&variables=${variables}`;
    let r = await fetch(url, { credentials: 'include' });
    r = await r.json();
    const list = r.data.user.edge_highlight_reels.edges;
    if (!list || !list.length) {
      alert('No highlights loaded');
      return;
    }
    createDialog();
    const statusEle = qS('.daCounter');
    statusEle.innerHTML = '<p>Select highlight to download:</p>'
    for (let i = 0; i < list.length; i++) {
      const n = list[i].node;
      const a = document.createElement('a');
      statusEle.appendChild(a);
      a.style.cssText = 'width: 100px; display: inline-block;';
      a.innerHTML = `<img src="${n.cover_media_cropped_thumbnail.url}" ` +
        `style="width:100%;" /><br>${n.title}`;
      a.addEventListener('click', () => loadStories(id, `"${n.id}"`));
    }
  } catch (e) {
    console.error(e);
    alert('Cannot load highlights');
  }
}

function getFbEnv() {
  const s = qSA('script');
  for (let i = 0; i < s.length; i += 1) {
    let t = s[i].textContent;
    if (t) {
      const m = t.match(/"USER_ID":"(\d+)"/);
      if (m) {
        uid = m[1];
      }
      if (t.indexOf('DTSGInitialData') > 0) {
        t = t.slice(t.indexOf('DTSGInitialData'));
        t = t.slice(0, t.indexOf('}')).split('"');
        fbDtsg = t[4];
      }
    }
  }
}
async function addVideoLink() {
  if (window.location.href.indexOf('/videos/') === -1) {
    return;
  }
  let id = window.location.href.match(/\/\d+\//g);
  if (!id) {
    return;
  }
  id = id[id.length - 1].slice(1, -1);
  if (!loadedPosts[id]) {
    loadedPosts[id] = 1;
    getFbEnv();
    const url = `https://www.facebook.com/video/tahoe/async/${id}/?chain=true&payloadtype=primary`;
    const options = {
      credentials: 'include',
      method: 'POST',
      headers: {
        'content-type': 'application/x-www-form-urlencoded',
      },
      body: `__user=${uid}&__a=1&fb_dtsg=${fbDtsg}`,
    };
    let r = await fetch(url, options);
    r = await r.text();
    r = JSON.parse(r.slice(9)).jsmods.instances;
    for (let idx = 0; idx < r.length; idx += 1) {
      const i = r[idx];
      if (i[1] && i[1].length && i[1][0] === 'VideoConfig') {
        const data = i[2][0].videoData[0];
        const src = data.hd_src_no_ratelimit || data.hd_src ||
          data.sd_src_no_ratelimit || data.sd_src;
        loadedPosts[id] = src;
      }
    }
  } else if (loadedPosts[id] === 1) {
    return;
  }
  const e = qSA('[data-utime]:not(.livetimestamp), .timestamp');
  for (let i = 0; i < e.length; i += 1) {
    if (!e[i].parentNode.querySelector('.dVideo')) {
      const a = document.createElement('a');
      a.className = 'dVideo';
      a.href = loadedPosts[id];
      a.download = '';
      a.target = '_blank';
      a.style.padding = '5px';
      a.title = '(provided by DownAlbum)';
      a.textContent = 'Download ↓';
      e[i].parentNode.appendChild(a);
    }
  }
}

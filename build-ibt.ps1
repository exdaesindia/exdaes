param(
  [string]$SourcePath = 'F:\IBT\Website\index.html',
  [string]$OutputPath = 'C:\Users\USER\Documents\New project\ibt-preview'
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Set-ContentUtf8 {
  param(
    [string]$Path,
    [string]$Value
  )
  $parent = Split-Path -Parent $Path
  Ensure-Dir -Path $parent
  [System.IO.File]::WriteAllText($Path, $Value, [System.Text.UTF8Encoding]::new($false))
}

$raw = Get-Content -LiteralPath $SourcePath -Raw

$encodingFixes = @(
  @{ From = (-join ([char]0x00E2, [char]0x20AC, [char]0x201C)); To = '-' },
  @{ From = (-join ([char]0x00E2, [char]0x20AC, [char]0x201D)); To = '&mdash;' },
  @{ From = (-join ([char]0x00E2, [char]0x20AC, [char]0x2122)); To = '&rsquo;' },
  @{ From = (-join ([char]0x00E2, [char]0x20AC, [char]0x0153)); To = '&ldquo;' },
  @{ From = (-join ([char]0x00E2, [char]0x20AC, [char]0x009D)); To = '&rdquo;' },
  @{ From = (-join ([char]0x00E2, [char]0x0153, [char]0x201C)); To = '&#10003;' }
)

foreach ($pair in $encodingFixes) {
  $raw = $raw.Replace($pair.From, $pair.To)
}

$mobileCss = @"
@media(max-width:768px){
  .ann{height:34px}
  nav{top:34px}
  .nav-inner{padding:0 14px;height:74px}
  .nav-logo img{height:58px}
  .mobile-menu{top:108px;padding:12px 16px 22px}
  .page{padding-top:108px}
  section{padding:56px 0}
  .container{padding:0 16px}
  .hero{min-height:auto}
  .hero-inner{grid-template-columns:1fr;gap:24px;padding:36px 16px 42px}
  .hero h1{font-size:34px}
  .hero-sub{font-size:15px}
  .hero-btns,.btn-gold,.btn-outline-white,.adm-btn{width:100%}
  .hero-btns a,.hero-btns button,.hero-btns .btn-gold,.hero-btns .btn-outline-white{justify-content:center;width:100%}
  .stats-grid{grid-template-columns:1fr 1fr}
  .stat-card{padding:16px}
  .adm-banner{flex-direction:column;align-items:flex-start}
  .sec-title{font-size:30px}
  .sec-desc{font-size:15px}
  .batch-tabs{max-width:none}
  .batch-tab{font-size:16px;padding:10px 12px}
  .batch-hdr{padding:22px 18px}
  .batch-hdr h2{font-size:30px}
  .price-head{padding:22px 18px 16px}
  .price-body{padding:18px}
  .price-amt{font-size:40px}
  .exc-tba{padding:28px 18px}
  .exc-boxes{grid-template-columns:1fr}
  .form-wrap{padding:24px 18px}
  .footer-inner{grid-template-columns:1fr;gap:26px}
  .footer-logo-img{height:64px !important}
  .footer-brand a{max-width:100%}
  .video-testimonial-grid{grid-template-columns:1fr !important}
}
@media(max-width:520px){
  .hero h1{font-size:30px}
  .hero-badge{font-size:11px}
  .exam-tags{gap:6px}
  .exam-tag{font-size:11px;padding:5px 10px}
  .stats-grid{grid-template-columns:1fr}
  .why-card,.testi-card,.feat-item,.price-card,.astat,.exc-box{padding-left:16px;padding-right:16px}
  .batch-hdr,.adm-banner,.form-wrap,.phone-mock{border-radius:14px}
  .phone-mock{width:100%;max-width:240px;height:auto;min-height:360px}
  .wa-float{right:14px;bottom:14px}
}
"@

$scriptBlock = @"
<script>
(function () {
  var currentPage = '__PAGE_KEY__';
  var visualPage = currentPage === 'online-course' ? 'online' : currentPage;
  var routes = {
    home: '__ROUTE_HOME__',
    about: '__ROUTE_ABOUT__',
    courses: '__ROUTE_COURSES__',
    app: '__ROUTE_APP__',
    contact: '__ROUTE_CONTACT__',
    'online-course': '__ROUTE_ONLINE__'
  };

  function activatePage(name) {
    document.querySelectorAll('.page').forEach(function (page) {
      page.classList.remove('active');
    });
    var target = document.getElementById('page-' + name);
    if (target) target.classList.add('active');
    document.querySelectorAll('.nav-links a[data-page]').forEach(function (link) {
      link.classList.toggle('active-nav', link.dataset.page === name || (name === 'online' && link.dataset.page === 'courses'));
    });
  }

  window.showPage = function (name) {
    var pageName = name === 'online' ? 'online-course' : name;
    var target = routes[pageName] || routes.home;
    if (pageName === 'courses' && window.location.hash) {
      window.location.href = target + window.location.hash;
      return;
    }
    window.location.href = target;
  };

  window.switchBatch = function (batch) {
    if (currentPage !== 'courses') {
      window.location.href = routes.courses + '#' + batch;
      return;
    }
    document.querySelectorAll('.batch-tab').forEach(function (tab) {
      tab.classList.remove('active');
    });
    document.querySelectorAll('.batch-panel').forEach(function (panel) {
      panel.classList.remove('active');
    });
    document.querySelectorAll('.batch-tab').forEach(function (tab) {
      var onClick = tab.getAttribute('onclick') || '';
      if (onClick.indexOf("'" + batch + "'") !== -1) {
        tab.classList.add('active');
      }
    });
    var panel = document.getElementById('panel-' + batch);
    if (panel) panel.classList.add('active');
    if (window.location.hash !== '#' + batch) {
      window.history.replaceState(null, '', '#' + batch);
    }
  };

  window.closeMob = function () {
    var menu = document.getElementById('mobileMenu');
    if (menu) menu.classList.remove('open');
  };

  document.addEventListener('DOMContentLoaded', function () {
    activatePage(visualPage);
    var logo = document.querySelector('.nav-logo');
    if (logo) {
      logo.style.cursor = 'pointer';
      logo.addEventListener('click', function () {
        window.location.href = routes.home;
      });
    }

    var hamburger = document.getElementById('hamburgerBtn');
    if (hamburger) {
      hamburger.addEventListener('click', function () {
        document.getElementById('mobileMenu').classList.toggle('open');
      });
    }

    document.querySelectorAll('.email-link').forEach(function (a) {
      var user = 'ibtgauhati';
      var domain = 'gmail.com';
      a.href = 'mailto:' + user + '@' + domain;
      a.textContent = user + '@' + domain;
    });

    if (currentPage === 'courses') {
      var batch = (window.location.hash || '').replace('#', '');
      switchBatch(batch || 'smart');
    }

    window.formspree = window.formspree || function () {
      (formspree.q = formspree.q || []).push(arguments);
    };
    formspree('initForm', { formElement: '#enquiry-form', formId: 'mjgpazwn' });
  });
})();
</script>
"@

$pages = @(
  @{
    Folder = ''
    PageKey = 'home'
    Title = 'IBT Guwahati - Best Bank, SSC, Railway Coaching in Guwahati | Assam'
    Description = 'Join IBT Guwahati for Bank, SSC, RBI, Railway and Government exam coaching with expert faculty, mock tests and proven results in Assam.'
    Canonical = 'https://ibtguwahati.org/'
    Sitemap = 'sitemap.xml'
    Routes = @{
      Home = './index.html'
      About = 'about/index.html'
      Courses = 'courses/index.html'
      App = 'app/index.html'
      Contact = 'contact/index.html'
      Online = 'online-course/index.html'
    }
  },
  @{
    Folder = 'about'
    PageKey = 'about'
    Title = 'About IBT Guwahati | Government Exam Coaching Institute'
    Description = 'Learn about IBT Guwahati, our faculty support, student-first teaching approach and why aspirants trust us for Bank, SSC and Government exam preparation.'
    Canonical = 'https://ibtguwahati.org/about/'
    Sitemap = '../sitemap.xml'
    Routes = @{
      Home = '../index.html'
      About = '../about/index.html'
      Courses = '../courses/index.html'
      App = '../app/index.html'
      Contact = '../contact/index.html'
      Online = '../online-course/index.html'
    }
  },
  @{
    Folder = 'courses'
    PageKey = 'courses'
    Title = 'Offline Coaching Courses | IBT Guwahati'
    Description = 'Explore Smart Batch and Excellence Batch course options at IBT Guwahati for Bank, SSC, Railways, ADRE and Government exam preparation.'
    Canonical = 'https://ibtguwahati.org/courses/'
    Sitemap = '../sitemap.xml'
    Routes = @{
      Home = '../index.html'
      About = '../about/index.html'
      Courses = '../courses/index.html'
      App = '../app/index.html'
      Contact = '../contact/index.html'
      Online = '../online-course/index.html'
    }
  },
  @{
    Folder = 'app'
    PageKey = 'app'
    Title = 'MakeMyExam App | IBT Guwahati'
    Description = 'Discover the MakeMyExam App from IBT Guwahati for online classes, mock tests, materials and convenient hybrid exam preparation.'
    Canonical = 'https://ibtguwahati.org/app/'
    Sitemap = '../sitemap.xml'
    Routes = @{
      Home = '../index.html'
      About = '../about/index.html'
      Courses = '../courses/index.html'
      App = '../app/index.html'
      Contact = '../contact/index.html'
      Online = '../online-course/index.html'
    }
  },
  @{
    Folder = 'contact'
    PageKey = 'contact'
    Title = 'Contact IBT Guwahati | Coaching Enquiry and Admissions'
    Description = 'Contact IBT Guwahati for admissions, coaching enquiries, location details, phone support and Government exam batch information.'
    Canonical = 'https://ibtguwahati.org/contact/'
    Sitemap = '../sitemap.xml'
    Routes = @{
      Home = '../index.html'
      About = '../about/index.html'
      Courses = '../courses/index.html'
      App = '../app/index.html'
      Contact = '../contact/index.html'
      Online = '../online-course/index.html'
    }
  },
  @{
    Folder = 'online-course'
    PageKey = 'online-course'
    Title = 'Online Course | IBT Guwahati'
    Description = 'Join the online course from IBT Guwahati for structured Government exam preparation with classes, study material and test support.'
    Canonical = 'https://ibtguwahati.org/online-course/'
    Sitemap = '../sitemap.xml'
    Routes = @{
      Home = '../index.html'
      About = '../about/index.html'
      Courses = '../courses/index.html'
      App = '../app/index.html'
      Contact = '../contact/index.html'
      Online = '../online-course/index.html'
    }
  }
)

$scriptPattern = '(?s)<script>\s*function showPage\(name\).*?</script>'
$titlePattern = '(?s)<title>.*?</title>'
$descriptionPattern = '(?m)<meta name="description" content=".*?">'

Ensure-Dir -Path $OutputPath

foreach ($page in $pages) {
  $html = $raw
  $html = $html -replace [regex]::Escape('</style>'), ($mobileCss + "`r`n</style>")
  $html = [regex]::Replace($html, $titlePattern, "<title>$($page.Title)</title>", 1)
  $html = [regex]::Replace($html, $descriptionPattern, "<meta name=`"description`" content=`"$($page.Description)`">", 1)
  $html = $html.Replace("content:'checkmark';content:'&#10003;';", "content:'\2713';")
  $html = $html.Replace('class="page active" id="page-home"', 'class="page" id="page-home"')
  $activeId = "class=`"page active`" id=`"page-$($page.PageKey.Replace('online-course','online'))`""
  $html = $html.Replace("class=`"page`" id=`"page-$($page.PageKey.Replace('online-course','online'))`"", $activeId)
  $html = $html.Replace('>Enroll in Excellence &#8594;</button>', '>Enroll Now &#8594;</button>')
  $html = $html.Replace('<button class="btn-gold" onclick="showPage(''contact'')" style="font-size:14px;padding:12px 0;width:100%;justify-content:center">Enroll Now &#8594;</button>', '')

  $headInsert = @"
<meta name="robots" content="index, follow">
<link rel="canonical" href="$($page.Canonical)">
<meta property="og:type" content="website">
<meta property="og:title" content="$($page.Title)">
<meta property="og:description" content="$($page.Description)">
<meta property="og:url" content="$($page.Canonical)">
<meta property="og:site_name" content="IBT Guwahati">
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="$($page.Title)">
<meta name="twitter:description" content="$($page.Description)">
"@

  $html = $html.Replace('<link rel="sitemap" type="application/xml" href="/sitemap.xml">', $headInsert + "`r`n<link rel=`"sitemap`" type=`"application/xml`" href=`"$($page.Sitemap)`">")

  $html = $html.Replace('onclick="showPage(''courses'');switchBatch(''smart'')"', "href=`"$($page.Routes.Courses)#smart`"")
  $html = $html.Replace('onclick="showPage(''courses'');switchBatch(''excellence'')"', "href=`"$($page.Routes.Courses)#excellence`"")
  $html = $html.Replace('onclick="showPage(''courses'');switchBatch(''online'')"', "href=`"$($page.Routes.Online)`"")

  $html = [regex]::Replace(
    $html,
    '<a([^>]*?)onclick="showPage\(''([^'']+)''\)(;closeMob\(\))?"([^>]*)>',
    {
      param($match)
      $key = switch ($match.Groups[2].Value) {
        'home' { 'Home' }
        'about' { 'About' }
        'courses' { 'Courses' }
        'app' { 'App' }
        'contact' { 'Contact' }
        'online' { 'Online' }
        default { 'Home' }
      }
      $href = $page.Routes[$key]
      '<a' + $match.Groups[1].Value + 'href="' + $href + '"' + $match.Groups[4].Value + '>'
    }
  )

  $newScript = $scriptBlock.Replace('__PAGE_KEY__', $page.PageKey)
  $newScript = $newScript.Replace('__ROUTE_HOME__', $page.Routes.Home)
  $newScript = $newScript.Replace('__ROUTE_ABOUT__', $page.Routes.About)
  $newScript = $newScript.Replace('__ROUTE_COURSES__', $page.Routes.Courses)
  $newScript = $newScript.Replace('__ROUTE_APP__', $page.Routes.App)
  $newScript = $newScript.Replace('__ROUTE_CONTACT__', $page.Routes.Contact)
  $newScript = $newScript.Replace('__ROUTE_ONLINE__', $page.Routes.Online)

  $html = [regex]::Replace($html, $scriptPattern, $newScript, 1)

  $targetDir = if ([string]::IsNullOrWhiteSpace($page.Folder)) { $OutputPath } else { Join-Path $OutputPath $page.Folder }
  Ensure-Dir -Path $targetDir
  Set-ContentUtf8 -Path (Join-Path $targetDir 'index.html') -Value $html
}

$robots = @"
User-agent: *
Allow: /

Sitemap: https://ibtguwahati.org/sitemap.xml
"@

$sitemap = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://ibtguwahati.org/</loc></url>
  <url><loc>https://ibtguwahati.org/about/</loc></url>
  <url><loc>https://ibtguwahati.org/courses/</loc></url>
  <url><loc>https://ibtguwahati.org/app/</loc></url>
  <url><loc>https://ibtguwahati.org/contact/</loc></url>
  <url><loc>https://ibtguwahati.org/online-course/</loc></url>
</urlset>
"@

Set-ContentUtf8 -Path (Join-Path $OutputPath 'robots.txt') -Value $robots
Set-ContentUtf8 -Path (Join-Path $OutputPath 'sitemap.xml') -Value $sitemap

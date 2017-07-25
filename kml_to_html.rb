#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

mid = '1nB4pU9_keVn7slUauCG0oTKDWlg'

doc = Nokogiri::XML(open("http://www.google.com/maps/d/kml?forcekml=1&mid=#{mid}"))

title = doc.css('Document').at_css('name').children.text
lists = "\n"
options = "\n<option value='' data-color='#d3a'>現在地點 Current Location</option>\n"

doc.css('Folder').each_with_index do |folder, index|
  lists += "<li class='active'><a href='#' data-group='#{index}'>#{folder.at_css('name').children.text}</a></li>\n"
  folder.css('Placemark').each do |placemark|
    name = placemark.at_css('name').children.text
    color = placemark.at_css('styleUrl').children.text.split('-')[2]
    coordinates = placemark.at_css('coordinates').children.text.strip.split(',')
    options += "<option value='#{coordinates[1]},#{coordinates[0]}' data-group='#{index}' data-color='##{color}'>#{name}</option>\n"
  end
end

html = <<-EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>#{title}</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <script src="https://code.jquery.com/jquery-3.2.1.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4=" crossorigin="anonymous"></script>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>

    <link rel="stylesheet" href="https://bootswatch.com/paper/bootstrap.min.css">

    <style>
      .nav-pills { margin: 20px 0; }
      .nav-pills > li > a { padding: 8px 10px; }
      .btn { margin: 5px 0; }
      .glyphicon-map-marker { color: #333; }
      .glyphicon-arrow-right { color: #999; }
      a:link, a:visited, a:visited:hover, a:hover, a:active { text-decoration: none; }
    </style>
  </head>

  <body>
    <div class="container">
      <h3>
        <a href="https://www.google.com/maps/d/viewer?mid=#{mid}&hl=en&usp=sharing" target="_blank">#{title}</a>
      </h3>

      <ul class="nav nav-pills">
        #{lists}
      </ul>

      <form class="form-horizontal">
        <div class="form-group">
          <label class="col-sm-1 control-label" for="from">From:</label>
          <div class="col-sm-11">
            <select id="from" class="form-control">
              #{options}
            </select>
          </div>
        </div>

        <div class="form-group">
          <label class="col-sm-1 control-label" for="to">To:</label>
          <div class="col-sm-11">
            <select id="to" class="form-control">
              #{options}
            </select>
          </div>
        </div>

        <div class="form-group">
          <div class="col-sm-11 col-sm-offset-1">
            <div class="radio">
              <label class="radio-inline">
                <input type="radio" name="mode" value="1" checked> Transit
              </label>
              <label class="radio-inline">
                <input type="radio" name="mode" value="2"> Driving
              </label>
              <label class="radio-inline">
                <input type="radio" name="mode" value="3"> Walking
              </label>
            </div>
          </div>
        </div>

        <div class="form-group">
          <div class="col-sm-11 col-sm-offset-1">
            <button class="btn btn-primary btn-block" type="button" id="route">Route</button>
          </div>
        </div>
      </form>

      <div class="panel panel-default">
        <div class="panel-heading">
          <h3 class="panel-title">
            <span class="glyphicon glyphicon-apple"></span> Apple Maps
          </h3>
        </div>
        <div class="panel-body" id="apple">
          No Route Yet
        </div>
      </div>

      <div class="panel panel-default">
        <div class="panel-heading">
          <h3 class="panel-title">
            <span class="glyphicon glyphicon-globe"></span> Google Maps
          </h3>
        </div>
        <div class="panel-body" id="google">
          No Route Yet
        </div>
      </div>
    </div>

    <script>
      var from_html = $('#from').html();
      var to_html = $('#to').html();

      $('.nav-pills a').on('click', function (event) {
        event.preventDefault();
        var group = $(this).data('group');
        $(this).closest('li').toggleClass('active');

        $('#from').html(from_html);
        $('#to').html(to_html);
        $('li:not([class^="active"])').each(function () {
          var hide_group = $(this).find('a').data('group');
          $(`option[data-group="${hide_group}"]`).remove();
        });
      });

      $('#from, #to, [name="mode"]').on('click', function () {
        $('#apple').empty().append('No Route Yet');
        $('#google').empty().append('No Route Yet');
      });

      $('#route').on('click', function () {
        var from_value = $('#from').val();
        var from_text = $('#from option:selected').text();
        var from_color = $('#from option:selected').data('color');
        var to_value = $('#to').val();
        var to_text = $('#to option:selected').text();
        var to_color = $('#to option:selected').data('color');
        var mode = $('[name="mode"]:checked').val();
        var href_text = `
          <span class="glyphicon glyphicon-map-marker"></span>
          <span style='color: ${from_color};'>${from_text}</span>
          &nbsp;<span class="glyphicon glyphicon-arrow-right"></span>&nbsp;
          <span class="glyphicon glyphicon-map-marker"></span>
          <span style='color: ${to_color};'>${to_text}</span>
        `;

        var mode_apple = 'r';
        var mode_google = 'transit';

        if (mode == 2) { mode_apple = 'd'; mode_google = 'driving'; }
        else if (mode == 3) { mode_apple = 'w'; mode_google = 'walking'; }

        var api_apple = `http://maps.apple.com/?saddr=${from_value}&daddr=${to_value}&dirflg=${mode_apple}`;
        var api_google = `https://www.google.com/maps/dir/?api=1&origin=${from_value}&destination=${to_value}&travelmode=${mode_google}`;

        $('#apple').empty().append(`<a href="${api_apple}" target="_blank">${href_text}</a>`);
        $('#google').empty().append(`<a href="${api_google}" target="_blank">${href_text}</a>`);
      });
    </script>
  </body>
</html>
EOF

File.write('index.html', html)

//https://ga-dev-tools.appspot.com/embed-api/third-party-visualizations/
//https://github.com/googleanalytics/ga-dev-tools/blob/master/src/javascript/embed-api/components/active-users.js#L69-L87

angular.module('cruprojects')
  //TODO: figure out what really needs to be injected here
.run([
  'EncouragmentCtrl',
  function (encouragement) {

    // add Google Analytics Script at the end of the page
    var gaCode = document.createTextNode('(function(w,d,s,g,js,fs){ g=w.gapi||(w.gapi={});g.analytics={q:[],ready:function(f){this.q.push(f);}}; js=d.createElement(s);fs=d.getElementsByTagName(s)[0]; js.src="https://apis.google.com/js/platform.js"; fs.parentNode.insertBefore(js,fs);js.onload=function(){g.load("analytics");}; }(window,document,"script"));');
    var scriptTag = document.createElement('script');
    scriptTag.type = 'text/javascript';
    scriptTag.appendChild(gaCode);
    document.body.appendChild(scriptTag);

    // if ga is ready -> inform service
    gapi.analytics.ready(function () {
      encouragement.start();
    });
  }
]);
  //TODO: import map and ga real time clients as services
  //TODO: split map into realtime-ga-map directive
.controller('EncouragmentCtrl', function($q) {
  var that = this;

  //TODO: get real instance of map
  that.map = new google.maps.Map(document.getElementById('map'), {
    zoom: 2,
    center: {lat: 17.8786938, lng: -28.8084722},
    mapTypeId: google.maps.MapTypeId.ROADMAP
  });

  //TODO: get real icons
  that.apps = [
    {
      id: 84323330,
      name: 'God Tools',
      icon: 'godtools.png',
      totalActiveUsers: 0,
      activeUsers: []
    },
    {
      id: 59955759,
      name: 'MPDX',
      icon: 'mpdx.png',
      totalActiveUsers: 0,
      activeUsers: []
    }
  ];

  that.options = {
    animateMap: true,
    animateMapFrequency: 5000,
    polling: true,
    pollingFrequency: 60000
  };

  //TODO: run through all the apps removing existing markers removeAppFromMap > getting active users getActiveUsers > putting new markers on map putAppOnMap
  //use setTimeout to make sure the app requests are spaced out.
  that.start = function() {

    /**
     * Authorize the user immediately if the user has already granted access.
     * If no access has been created, render an authorize button inside the
     * element with the ID "embed-api-auth-container".
     */
    gapi.analytics.auth.authorize({
      container: 'embed-api-auth-container',
      clientid: 'REPLACE WITH YOUR CLIENT ID'
    });

    // Wait until the user is authorized.
    if (gapi.analytics.auth.isAuthorized()) {
      that.startPollingForApps(that.apps);
    }
    else {
      gapi.analytics.auth.once('success', this.startPollingForApps.bind(that));
    }
  };

  that.startPollingForApps = function(apps) {

    var currentAppIndex = 0;
    var appPollingOffset = that.options.pollingFrequency / apps.length;
    for (app in apps) {

      setTimeout(function() {
        that.pollForApp(app);
      }, currentAppIndex * appPollingOffset);

      numberOfApps++;
    }

  };

  that.pollForApp = function(app) {

    setTimeout(function() {
      that.removeAppFromMap(app, that.map);

      that.getActiveUsers(app).then(function (appWithLocation) {
        that.putAppOnMap(appWithLocation)
      }, function (error) {
        //TODO: do something intelligent with timeout error
      });

      if (that.options.polling) {
        that.pollForApp(app);
      }
    }, that.options.pollingFrequency);

  };

  that.rotateMap = function() {
    setTimeout(function(){
      var location = that.map.getCenter();
      location.lng += 5;
      that.map.panTo(location);
      if (that.options.animateMap) {
        that.rotateMap();
      }
    }, that.options.animateMapFrequency);
  };

  that.getActiveUsers = function(app) {

    var deferred = $q.defer();

    gapi.client.analytics.data.realtime
      .get({ids:'ga:' + app.id, metrics:'rt:activeUsers', dimensions: 'rt:country,rt:region,rt:city'})
      .execute(function(response) {

        var countryHeader = 0;
        var regionHeader = 1;
        var cityHeader = 2;
        var activeUserHeader = 3;
        var newValue = response.totalResults ? +response.rows[0][0] : 0;
        var oldValue = app.totalActiveUsers;

        if (newValue != oldValue) {
          app.totalActiveUsers = newValue;
        }

        for (header = 0; header < response.columnHeaders; header++) {
          if (response.columnHeader[header].name == 'rt:country') {
            countryHeader = header;
          } else if (response.columnHeader[header].name == 'rt:region') {
            regionHeader = header;
          } else if (response.columnHeader[header].name == 'rt:city') {
            cityHeader = header;
          } else if (response.columnHeader[header].name == 'rt:activeUsers') {
            activeUserHeader = header;
          }
        }

        app.activeUsers = [];
        var completedLocations = 0;
        for(row in response.rows) {

          var usersAtLocation = {
            id: row[countryHeader] + '-' + row[cityHeader],
            country: row[countryHeader],
            region: row[regionHeader],
            city: row[cityHeader],
            activeUsers: row[activeUserHeader]
          };

          that.getLocation(usersAtLocation).then(function(location){
            usersAtLocation.location = location;
            completedLocations++;

            if (completedLocations == response.rows.length) {
              deferred.resolve(app);
            }

          }, function(error){
            alert(error.message);
            completedLocations++;

            if (completedLocations == response.rows.length) {
              deferred.resolve(app);
            }

          });

          app.activeUsers.push(usersAtLocation);
        }

      });

    return deferred.promise;
  };

  that.getLocation = function(activeUsers) {

    var deferred = $q.defer();

    if (that.locationCache[activeUsers.id]) {
      deferred.resolve(that.locationCache[activeUsers.id]);
      return deferred.promise;
    }

    //TODO: get real instance of geocoder
    var geocoder = new google.maps.Geocoder();
    var address = activeUsers.city + ', ' + activeUsers.region + ' ' + activeUsers.country;
    geocoder.geocode({'address': address}, function(results, status) {

      if (status === google.maps.GeocoderStatus.OK) {
        that.locationCache[activeUsers.id] = results[0].geometry.location;
        deferred.resolve(that.locationCache[activeUsers.id]);
      } else {
        deferred.reject({message:'Geocode was not successful for the following reason: ' + status});
      }

    });

    return deferred.promise;
  };

  that.putAppOnMap = function(app, map) {

    var marker;

    for (users in app.activeUsers) {

      if (users.location) {
        //TODO: get real instance of marker
        users.marker = new google.maps.Marker({
          map: that.map,
          icon: app.icon,
          label: users.activeUsers,
          draggable: false,
          position: users.location
        });
      }

    }

  };

  that.removeAppFromMap = function(app, map) {

    var marker;

    for (users in app.activeUsers) {

      if (users.marker) {
        users.marker.setMap(null);
        delete users.marker;
      }

    }

  };

});
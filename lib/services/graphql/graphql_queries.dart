const String planQuery = r'''
query Plan(
  $arriveBy: Boolean
  $banned: InputBanned
  $bikeReluctance: Float
  $carReluctance: Float
  $date: String
  $fromPlace: String!
  $modes: [TransportMode]
  $numItineraries: Int
  $preferred: InputPreferred
  $time: String
  $toPlace: String!
  $unpreferred: InputUnpreferred
  $walkReluctance: Float
  $walkSpeed: Float
  $wheelchair: Boolean
  $minTransferTime: Int
  $transitPassFilter: [String]
  $comfortLevels: [String]
  $searchParameters: [String]
  $distributionChannel: String!,
  $distributionSubChannel: String!
  $passengers: [PassengerInput]
  $pageCursor: String
) 
{
  plan(
    arriveBy: $arriveBy
    banned: $banned
    bikeReluctance: $bikeReluctance
    carReluctance: $carReluctance
    date: $date
    fromPlace: $fromPlace
    locale: "hu"
    numItineraries: $numItineraries
    preferred: $preferred
    time: $time
    toPlace: $toPlace
    transportModes: $modes
    unpreferred: $unpreferred
    walkReluctance: $walkReluctance
    walkSpeed: $walkSpeed
    wheelchair: $wheelchair
    minTransferTime: $minTransferTime
    transitPassFilter: $transitPassFilter
    comfortLevels: $comfortLevels
    searchParameters: $searchParameters
    distributionChannel: $distributionChannel,
    distributionSubChannel: $distributionSubChannel
    passengers: $passengers
    pageCursor: $pageCursor
) {
  itineraries {
    accessibilityScore
    duration
    numberOfTransfers
    trackClosure
    endTime

    legs {     
      agency {
      
        alerts {
          alertDescriptionText
          alertHeaderText
          alertUrl
          effectiveStartDate
          id
        }
        id
        name
        timezone
        url
      }
        
      fareProducts {
        id
        product {
          __typename
          id
          name
          ... on DefaultFareProduct {
            medium {
              id
              name
            }
            riderCategory{
              id
              name
            }
            price {
              amount
              currency {
                code
                digits
              }
            }
          }
        }
      }
      accessibilityScore
      arrivalDelay
      departureDelay
      distance
      dropoffType
      duration
      endTime
      boardingPlatformColor
      alightingPlatformColor
        
      infoServices(language: "hu", onlyDisplayable: true) {
        name
        fontCode
        displayable
        fontCharSet
        fromStopIndex
        tillStopIndex
        fromStop {
          name
          stopId: id
        }
        tillStop {
              name
          stopId: id
        }
      }
      from {      
        lat
        lon
        name
        rentalVehicle {
          id
          network
        }
        stop {
        
          alerts {
            alertDescriptionText
            alertHeaderText
            alertUrl
            effectiveStartDate
            id
          }
          stationUicPricingCode
          code
          gtfsId
          id
          platformCode
          timezone
        }
      }
      headsign
      intermediatePlace
      legGeometry {
        length
        points
      }
        mode
        realTime
        realtimeState
        route {
          shortName
          longName
          mode
          color
          textColor
          agency {
            id
            name
          }
        }
        
        startTime
        to {
          lat
          lon
          name
          stop {
            code
            gtfsId
            id
            name
            platformCode
            timezone
          }
        }
        transitLeg
        trip {
          gtfsId
          tripHeadsign
          tripShortName
        }
      }
      startTime
      walkDistance
      emissionsPerPerson {
        co2
      }
    }
    from {
      name
      stop {
        gtfsId
      }
    }
    to {
      name
      stop {
        gtfsId
      }
    }
    nextPageCursor
  }
}
''';

const String tripDetailsQuery = r'''
query TripDetails($tripId: String!, $serviceDay: String!) {
  trip(id: $tripId, serviceDay: $serviceDay) {
    id: gtfsId
    tripShortName
    tripHeadsign
    alerts(types: [ROUTE, TRIP]) {
      id
      alertCause
      alertHeaderText
      alertDescriptionText
      alertSeverityLevel
      alertUrl
      effectiveStartDate
      effectiveEndDate
      alertHeaderTextTranslations {
        language
        text
      }
      alertDescriptionTextTranslations {
        language
        text
      }
      alertUrlTranslations {
        language
        text
      }
    }
    route {
      id: gtfsId
      mode
      shortName
      longName
      color
      textColor
      alerts(types: [STOPS_ON_ROUTE]) {
        id
        alertCause
        alertHeaderText
        alertDescriptionText
        alertSeverityLevel
        alertUrl
        effectiveStartDate
        effectiveEndDate
        alertHeaderTextTranslations {
          language
          text
        }
        alertDescriptionTextTranslations {
          language
          text
        }
        alertUrlTranslations {
          language
          text
        }
      }
    }
    stoptimes {
      realtime
      scheduledArrival
      realtimeArrival
      arrivalDelay
      scheduledDeparture
      realtimeDeparture
      departureDelay
      stop {
        id: gtfsId
        name
        lat
        lon
        bearing
        platformCode
        alerts(types: [STOP_ON_ROUTES, STOP_ON_TRIPS, STOP]) {
          id
          alertCause
          alertHeaderText
          alertDescriptionText
          alertSeverityLevel
          alertUrl
          effectiveStartDate
          effectiveEndDate
          alertHeaderTextTranslations {
            language
            text
          }
          alertDescriptionTextTranslations {
            language
            text
          }
          alertUrlTranslations {
            language
            text
          }
        }
      }
    }
    tripGeometry {
      length
      points
    }
    vehiclePositions {
      nextStop {
        arrivalDelay
        stop {
          name
        }
      }
      prevOrCurrentStop {
        arrivalDelay
        departureDelay
      }
      vehicleId
      isEstimated
      label
      licensePlate
      uicCode
      vehicleModel
      heading
      lat
      lon
      trip {
        tripShortName
        gtfsId
      }
    }
  }
}
''';

String buildVehiclePositionsQuery(String modesLiteral) =>
    '''
query VehiclePositions(
  \$swLat: Float!
  \$swLon: Float!
  \$neLat: Float!
  \$neLon: Float!
) {
  vehiclePositions(
    swLat: \$swLat
    swLon: \$swLon
    neLat: \$neLat
    neLon: \$neLon
    modes: [$modesLiteral]
  ) {
    vehicleId
    lat
    lon
    heading
    vehicleModel
    label
    uicCode
    licensePlate
    stopRelationship {
      status
      stop {
        name
      }
    }
    nextStop {
      arrivalDelay
    }
    prevOrCurrentStop {
      arrivalDelay
      departureDelay
    }
    trip {
      gtfsId
      serviceDate
      routeShortName
      tripShortName
      tripHeadsign
      route {
        mode
        color
        textColor
      }
    }
  }
}
''';

const String stopsByBboxQuery = r'''
query StopsByBbox(
  $minLat: Float!
  $minLon: Float!
  $maxLat: Float!
  $maxLon: Float!
) {
  stopsByBbox(
    minLat: $minLat
    minLon: $minLon
    maxLat: $maxLat
    maxLon: $maxLon
  ) {
    gtfsId
    name
    lat
    lon
    bearing
  }
}
''';

const String stopQuickInfoQuery = r'''
query StopQuickInfo($stopId: String!) {
  stop(id: $stopId) {
    name
    routes(includeSiblingStops: false){
      gtfsId
      shortName
      longName
      mode
      color
      textColor
    }
  }
}
''';

String buildStopDetailsQuery(List<String> expandedIds) {
  final aliasLines = <String>[];
  for (var i = 0; i < expandedIds.length; i++) {
    final idLiteral = _graphqlStringLiteral(expandedIds[i]);
    aliasLines.add('''
  stop$i: stop(id: "$idLiteral") {
    gtfsId
    name
    lat
    lon
    bearing
    routes {
      gtfsId
      shortName
      color
      textColor
    }
    alerts(types: [STOP_ON_ROUTES, STOP_ON_TRIPS, STOP]) {
      id
      alertCause
      alertHeaderText
      alertDescriptionText
      alertSeverityLevel
      alertUrl
      effectiveStartDate
      effectiveEndDate
      alertHeaderTextTranslations {
        language
        text
      }
      alertDescriptionTextTranslations {
        language
        text
      }
      alertUrlTranslations {
        language
        text
      }
    }
    stoptimesForPatterns(startTime: \$startTime, numberOfDepartures: \$number, timeRange: \$timeRange) {
    times: stoptimes {
    realtime
      pickupType
      dropoffType
      scheduledArrival
      realtimeArrival
      arrivalDelay
      scheduledDeparture
      realtimeDeparture
      departureDelay
      serviceDay
      headsign
      stop {
        platformCode
      }
      trip {
        gtfsId
        tripShortName
        tripHeadsign
        route {
          shortName
          color
          textColor
        }
      }
    }
      
    }
  }
''');
  }

  return '''
query StopDetails(\$startTime: Long!, \$number: Int!, \$timeRange: Int!) {
${aliasLines.join('\n')}
}
''';
}

String _graphqlStringLiteral(String value) {
  return value.replaceAll('\\', r'\\').replaceAll('"', r'\"');
}

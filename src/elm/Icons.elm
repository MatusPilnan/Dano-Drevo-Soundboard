module Icons exposing (..)

import Svg
import Svg.Attributes as SvgAttr
import Html exposing (Html)


menu : Html msg
menu =
    Svg.svg
        [ SvgAttr.class "h-6 w-6"
        , SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        ]
        [ Svg.path
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            , SvgAttr.d "M4 6h16M4 12h16M4 18h16"
            ]
            []
        ]

sound : Html msg
sound =
    Svg.svg
        [ SvgAttr.class "h-5 w-5"
        , SvgAttr.viewBox "0 0 20 20"
        , SvgAttr.fill "currentColor"
        ]
        [ Svg.path
            [ SvgAttr.d "M18 3a1 1 0 00-1.196-.98l-10 2A1 1 0 006 5v9.114A4.369 4.369 0 005 14c-1.657 0-3 .895-3 2s1.343 2 3 2 3-.895 3-2V7.82l8-1.6v5.894A4.37 4.37 0 0015 12c-1.657 0-3 .895-3 2s1.343 2 3 2 3-.895 3-2V3z"
            ]
            []
        ]
    

close : Html msg
close =
    Svg.svg
        [ SvgAttr.class "h-6 w-6"
        , SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        ]
        [ Svg.path
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            , SvgAttr.d "M6 18L18 6M6 6l12 12"
            ]
            []
        ]


read : Html msg
read =
    Svg.svg
        [ SvgAttr.class "h-5 w-5"
        , SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        ]
        [ Svg.path
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            , SvgAttr.d "M3 19v-8.93a2 2 0 01.89-1.664l7-4.666a2 2 0 012.22 0l7 4.666A2 2 0 0121 10.07V19M3 19a2 2 0 002 2h14a2 2 0 002-2M3 19l6.75-4.5M21 19l-6.75-4.5M3 10l6.75 4.5M21 10l-6.75 4.5m0 0l-1.14.76a2 2 0 01-2.22 0l-1.14-.76"
            ]
            []
        ]


check : Html msg
check =
    Svg.svg
        [ SvgAttr.class "h-5 w-5"
        , SvgAttr.viewBox "0 0 20 20"
        , SvgAttr.fill "currentColor"
        ]
        [ Svg.path
            [ SvgAttr.fillRule "evenodd"
            , SvgAttr.d "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
            , SvgAttr.clipRule "evenodd"
            ]
            []
        ]
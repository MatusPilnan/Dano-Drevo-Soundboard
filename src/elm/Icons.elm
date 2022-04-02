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
    
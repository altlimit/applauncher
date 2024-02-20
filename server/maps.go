package main

var categories = map[string]string{
	"ART_AND_DESIGN":      "Art & Design",
	"AUTO_AND_VEHICLES":   "Auto & Vehicles",
	"BEAUTY":              "Beauty",
	"BOOKS_AND_REFERENCE": "Books & Reference",
	"BUSINESS":            "Business",
	"COMICS":              "Comics",
	"COMMUNICATION":       "Communication",
	"DATING":              "Dating",
	"EDUCATION":           "Education",
	"ENTERTAINMENT":       "Entertainment",
	"EVENTS":              "Events",
	"FINANCE":             "Finance",
	"FOOD_AND_DRINK":      "Food & Drink",
	"HEALTH_AND_FITNESS":  "Health & Fitness",
	"HOUSE_AND_HOME":      "House & Home",
	"LIFESTYLE":           "Lifestyle",
	"MAPS_AND_NAVIGATION": "Maps & Navigation",
	"MEDICAL":             "Medical",
	"MUSIC_AND_AUDIO":     "Music & Audio",
	"NEWS_AND_MAGAZINES":  "News & Magazines",
	"PARENTING":           "Parenting",
	"PERSONALIZATION":     "Personalization",
	"PHOTOGRAPHY":         "Photography",
	"PRODUCTIVITY":        "Productivity",
	"SHOPPING":            "Shopping",
	"SOCIAL":              "Social",
	"SPORTS":              "Sports",
	"TOOLS":               "Tools",
	"TRAVEL_AND_LOCAL":    "Travel & Local",
	"VIDEO_PLAYERS":       "Video Players & Editors",
	"WEATHER":             "Weather",
	"LIBRARIES_AND_DEMO":  "Libraries & Demo",
	"GAME_ARCADE":         "Arcade",
	"GAME_PUZZLE":         "Puzzle",
	"GAME_CARD":           "Cards",
	"GAME_CASUAL":         "Casual",
	"GAME_RACING":         "Racing",
	"GAME_SPORTS":         "Sport Games",
	"GAME_ACTION":         "Action",
	"GAME_ADVENTURE":      "Adventure",
	"GAME_BOARD":          "Board",
	"GAME_CASINO":         "Casino",
	"GAME_EDUCATIONAL":    "Educational",
	"GAME_MUSIC":          "Music Games",
	"GAME_ROLE_PLAYING":   "Role Playing",
	"GAME_SIMULATION":     "Simulation",
	"GAME_STRATEGY":       "Strategy",
	"GAME_TRIVIA":         "Trivia",
	"GAME_WORD":           "Word Games",
	"ANDROID_WEAR":        "Android Wear",
}

var categoryMigrate = map[string]string{
	"TRANSPORTATION":  "MAPS_AND_NAVIGATION",
	"MEDIA_AND_VIDEO": "VIDEO_PLAYERS",
	"ARCADE":          "GAME_ARCADE",
	"BRAIN":           "GAME_PUZZLE",
	"CARDS":           "GAME_CARD",
	"CASUAL":          "GAME_CASUAL",
	"RACING":          "GAME_RACING",
	"SPORTS_GAMES":    "GAME_SPORTS",
	"APP_WALLPAPER":   "PERSONALIZATION",
	"APP_WIDGETS":     "PERSONALIZATION",
}

var userAgents = map[string]bool{
	"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)":                                                                                      true,
	"Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0)":                                                                                      true,
	"Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)":                                                                                                   true,
	"Mozilla/5.0 (Windows NT 6.1; Intel Mac OS X 10.6; rv:7.0.1) Gecko/20100101 Firefox/7.0.1":                                                             true,
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:7.0.1) Gecko/20100101 Firefox/7.0.1":                                                                  true,
	"Mozilla/5.0 (Windows NT 6.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1":                                                                                  true,
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0.1) Gecko/20100101 Firefox/4.0.1":                                                                  true,
	"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3":               true,
	"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_2 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8H7 Safari/6533.18.5": true,
	"Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3":                        true,
	"Mozilla/5.0 (iPad; CPU OS 4_3_2 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8H7 Safari/6533.18.5":             true,
	"Mozilla/5.0 (Linux; U; Android 2.3.6; en-us; Nexus S Build/GRK39F) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1":             true,
	"Mozilla/5.0 (Linux; U; Android 4.0.2; en-us; Galaxy Nexus Build/ICL53F) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30":      true,
	"Mozilla/5.0 (PlayBook; U; RIM Tablet OS 2.1.0; en-US) AppleWebKit/536.2+ (KHTML, like Gecko) Version/7.2.1.0 Safari/536.2+":                           true,
	"Mozilla/5.0 (BlackBerry; U; BlackBerry 9900; en-US) AppleWebKit/534.11+ (KHTML, like Gecko) Version/7.0.0.187 Mobile Safari/534.11+":                  true,
	"Mozilla/5.0 (BB10; Touch) AppleWebKit/537.1+ (KHTML, like Gecko) Version/10.0.0.1337 Mobile Safari/537.1+":                                            true,
	"Mozilla/5.0 (MeeGo; NokiaN9) AppleWebKit/534.13 (KHTML, like Gecko) NokiaBrowser/8.5.0 Mobile Safari/534.13":                                          true,
}

// GetCatID return migrated category
func GetCatID(c string) string {
	if v, ok := categoryMigrate[c]; ok {
		return v
	}
	if _, ok := categories[c]; ok {
		return c
	}
	return ""
}

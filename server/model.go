package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"regexp"
	"strings"
	"time"

	"google.golang.org/appengine/v2/datastore"
	"google.golang.org/appengine/v2/memcache"
)

type (
	// Application stores the model for application
	Application struct {
		ID       string    `datastore:"-" goon:"id"`
		Updated  time.Time `datastore:"updated,noindex"`
		Category string    `datastore:"category,noindex"`
		Custom   []byte    `datastore:"custom,noindex"`
	}
)

var (
	catRe = regexp.MustCompile(`"/store/apps/category/([^"]+)"]`)
)

// GetCategory search a category
func (a *Application) GetCategory(ctx *Context) string {
	ctx.Debugf("Fetching %s from play store...", a.ID)
	client := &http.Client{}
	req, err := http.NewRequest("GET", "https://play.google.com/store/apps/details?id="+a.ID, nil)
	if err != nil {
		ctx.Debugf("GetCategory NewRequest Err: %s", err)
		return ""
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36")
	resp, err := client.Do(req)
	if err != nil {
		ctx.Debugf("GetCategory Err: %s", err)
		return ""
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		ctx.Debugf("GetCategory Read Err: %s", err)
		return ""
	}

	html := string(body[:])
	if strings.Contains(html, "<title>Not Found</title>") {
		ctx.Debugf("GetCategory not found")
		return ""
	}
	matches := catRe.FindAllStringSubmatch(html, -1)
	if len(matches) < 2 {
		ctx.Debugf("Regex no match")
		return ""
	}
	cat := matches[1][1]
	if _, ok := categories[cat]; ok {
		g := ctx.Goon()
		a.Category = cat
		a.Updated = time.Now()
		g.Put(a)
		return cat
	}
	return ""
}

// GetCustom returns an array of Value from bytes
func (a *Application) GetCustom() map[string]int {
	custom := make(map[string]int)
	if a.Custom != nil {
		json.Unmarshal(a.Custom, &custom)
	}
	return custom
}

// SetCustom sets the custom
func (a *Application) SetCustom(custom map[string]int) error {
	c, err := json.Marshal(custom)
	if err != nil {
		return err
	}
	a.Custom = c
	return nil
}

// GetApplicationCategory returns application category
func GetApplicationCategory(ctx *Context, pid string) string {
	a := &Application{ID: pid}
	g := ctx.Goon()
	err := g.Get(a)
	if err == datastore.ErrNoSuchEntity || GetCatID(a.Category) == "" && len(a.Custom) == 0 {
		key := "fetch_" + a.ID
		if cache, err := memcache.Get(ctx.AEContext, key); err == nil {
			ctx.Debugf("%s = %s found in cache", a.ID, cache)
			return string(cache.Value[:])
		}
		cat := a.GetCategory(ctx)
		if cat != "" {
			cache := &memcache.Item{
				Key:        key,
				Value:      []byte(cat),
				Expiration: time.Hour * 168,
			}
			memcache.Set(ctx.AEContext, cache)
		}
		return GetCatID(cat)
	} else if err != nil {
		ctx.Debugf("Err: %s", err)
		return ""
	}
	if a.Category == "" && a.Custom != nil {
		c := a.GetCustom()
		m := 0
		cat := ""
		for k, v := range c {
			if v > m {
				m = v
				cat = k
			}
		}
		return GetCatID(cat)
	}
	return GetCatID(a.Category)
}

// SubmitAppSuggestions stores to custom field {category:++}
func SubmitAppSuggestions(ctx *Context, cat string, pids []string) {
	if _, ok := categories[cat]; !ok {
		return
	}
	apps := make([]*Application, len(pids))
	g := ctx.Goon()

	for k, v := range pids {
		apps[k] = &Application{ID: v}
	}

	g.GetMulti(apps)
	for _, app := range apps {
		c := app.GetCustom()
		if val, ok := c[cat]; ok {
			c[cat] = val + 1
		} else {
			c[cat] = 1
		}
		app.SetCustom(c)
		ctx.Debugf("Suggestion for %s with %s result %s", app.ID, cat, app.Custom)
	}
	g.PutMulti(apps)
}

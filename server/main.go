package main

import (
	"net/http"
	"strings"
	"sync"

	"github.com/labstack/echo"
	"google.golang.org/appengine/v2"
	"google.golang.org/appengine/v2/mail"
)

const miscCategory = "MISC"

func main() {
	appengine.Main()
}

func createMux() *echo.Echo {
	e := echo.New()
	http.Handle("/", e)
	return e
}

var e = createMux()

func init() {

	e.GET("/applauncher/cron", func(c echo.Context) error {
		ctx := MakeContext(c)
		a := &Application{ID: "com.google.android.calendar"}
		if c.QueryParam("failtest") == "1" {
			a.ID += "1"
		}
		cat := a.GetCategory(ctx)
		if cat != "PRODUCTIVITY" {
			msg := &mail.Message{
				Sender:  "noreply@altlimit-api.appspotmail.com",
				Subject: "Category Detection Failed",
				Body:    "AppLauncher is not returning the right category.",
			}
			if err := mail.SendToAdmins(ctx.AEContext, msg); err != nil {
				ctx.Debugf("Failed to send email to admins: %v", err)
			}
		}
		return nil
	})

	e.GET("/applauncher/category", func(c echo.Context) error {
		ctx := MakeContext(c)
		pid := c.QueryParam("id")
		ua := c.Request().Header.Get("User-Agent")

		ctx.Debugf("PackageID: %s", pid)

		if _, ok := userAgents[ua]; !ok {
			ctx.Debugf("Blocked invalid user agent")
			return nil
		}

		if pid != "" {
			cat := GetApplicationCategory(ctx, pid)
			return c.String(http.StatusOK, cat)
		}

		return nil
	})

	e.POST("/applauncher/suggest", func(c echo.Context) error {
		ctx := MakeContext(c)
		apps := c.FormValue("apps")
		if apps == "" {
			apps = c.QueryParam("apps")
		}
		pids := strings.Split(apps, ",")
		cat := c.FormValue("category")
		if cat == "" {
			cat = c.QueryParam("category")
		}

		ctx.Debugf("Suggested %v -> %v", cat, pids)
		SubmitAppSuggestions(ctx, cat, pids)
		return nil
	})

	e.POST("/applauncher/import", func(c echo.Context) error {
		ctx := MakeContext(c)
		apps := c.FormValue("apps")
		result := make(map[string]string)
		if apps == "" {
			apps = c.QueryParam("apps")
		}
		if apps == "" {
			return c.JSON(http.StatusOK, result)
		}
		pids := strings.Split(apps, ",")
		var (
			mu sync.Mutex
			wg sync.WaitGroup
		)
		for k, v := range pids {
			go func(pid string) {
				defer wg.Done()
				defer mu.Unlock()

				cat := GetApplicationCategory(ctx, pid)
				mu.Lock()
				if cat != "" {
					result[pid] = cat
				}
			}(v)
			wg.Add(1)

			if k%50 == 0 {
				wg.Wait()
			}
		}
		wg.Wait()
		ctx.Debugf("Result: %v", result)
		return c.JSON(http.StatusOK, result)
	})
}

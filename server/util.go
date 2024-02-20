package main

import (
	"context"
	"net/http"

	"github.com/labstack/echo"
	"github.com/mjibson/goon/v2"
	"google.golang.org/appengine/v2"
	"google.golang.org/appengine/v2/log"
)

// Context wraps appengine and echo context
type Context struct {
	echo.Context
	goon       *goon.Goon
	httpClient *http.Client

	AEContext context.Context
}

// MakeContext creates our Context
func MakeContext(c echo.Context) *Context {
	ctx := &Context{
		Context:   c,
		AEContext: appengine.NewContext(c.Request()),
	}
	ctx.goon = goon.FromContext(ctx.AEContext)
	return ctx
}

// Goon returns the current context instance of goon
func (c *Context) Goon() *goon.Goon {
	return c.goon
}

// Debugf shortcut for log.Debugf
func (c *Context) Debugf(format string, args ...interface{}) {
	log.Debugf(c.AEContext, format, args...)
}

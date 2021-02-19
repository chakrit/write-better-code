# Comparing Boolean Expression to True

This has to be the oldest trick in the book in the sense that only really early beginner
make these mistakes.

#### Instead of

```ruby
class User
  attr_reader :username
  attr_reader :email

  def is_valid?
    valid = !self.username.blank? && !self.password.blank?
    valid == true
  end
end
```

#### Do this

```ruby
class User
  attr_reader :username
  attr_reader :email

  def is_valid?
    !self.username.blank? && !self.password.blank?
  end
end
```

## Why?

Boolean expressions eventually resolve to either `true` or `false`. Comparing them again
to `true` wastes computation and adds extra cognitive load without actually adding to the
readability or explicitlness.

## Transgression

Sometimes you don't always have a binary `true` or `false` values. For example, you can
have `undefined`, `null` or `nil` values in other languages. In which case, comparing them
to `true` do have a use because you want to avoid the other two (or three) possibility of
the value not existing, or the value being `false` at the same time.

```typescript
let result = render(template);                  // default options `{}`
result = render(template, { escape: true });    // explicit options

function render(content, options = {}) {
  if (options['escape'] === true) {
    content = htmlEscape(content)
  }

  // ...
}
```

It may, however, confuses the reader because the absence of value is implicit in this
context. Calling out implicitness usually improves readability but reduce succintness and
adds conginitive load. So depending on your situation, shorter may be better or explicit
may be better.

One way to make this explicit is to split apart the two concerns in the code:

1. Checking for absence of value
2. Checking for the value itself

Like so:

```typescript
function render(content, options = {}) {
  if (typeof options['escape'] !== 'undefined' && options['escape']) {
    content = htmlEscape(content)
  }

  // ...
}
```

This code calls out to the reader to be on the lookout for the absence of values in the
`options` hash. That not all options maybe passed into the function.

Alternatively, we can eliminate 1) entirely by supplying defaults:

```typescript
function render(content, options = {}) {
  if (!options.hasOwnProperty('escape')) {
    options['escape'] = defaults['escape']
  }

  // now we are sure the 'escape` option will always be specified
  // our check is now straightforward
  if (options['escape']) {
    content = htmlEscape(content)
  }

  // ...
}
```

An experienced coder will also notice that the pattern of "applying defaults" can be made
more generic and applied uniformly throughout the codebase. This is exactly the usecase of
[lodash's _.defaults() method](https://www.geeksforgeeks.org/lodash-_-defaults-method/)
which we can use to make the code more succinct:

```typescript
function render(content, options = {}) {
  _.defaults(options, defaults); // eliminate any "absence of value" cases

  if (options['escape']) {
    content = htmlEscape(content)
  }

  // ...
}
```

We can avoid Lodash entirely and use null-coalescing operator `??` if your language supports
them:

```typescript
function render(content, options = {}) {
  if (options['escape'] ?? false) {
    content = htmlEscape(content)
  }

  // ...
}
```

## Similar:

* (TODO) Comparing Expression to its value

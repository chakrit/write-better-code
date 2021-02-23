# If/Else Pyramids

When writing complex method or important "core logic" code paths. We often need to add
many branching and condition switches. If we are not careful, we can end up with a
"pyramid" built on indentation upon indentation due to the need to add conditional
branches over and over during the liftime of the code as new business logic are
discovered and handled.

Often, however, the method usually do have a central "happy path" that does the most
meaningful and important work. We can focus on highlight this "happy path" to keep the
method obvious as to its purpose and remains highly readable.

## Example

```ruby
class Payment
  attr_reader :method
  attr_reader :card_number
  attr_reader :wallet_address
  attr_reader :paid

  def process
    if !paid
      if method == :credit_card
        if !Luhn.check(self.card_number)
          raise 'invalid CC number'
        else
          CreditCard.process(self)
        end
      elsif method == :bitcoin
        if !BTC.check_address(self.wallet_address)
          raise 'invalid BTC wallet address'
        else
          BTC.process(self)
        end
      end
    end
  end
end
```

There are several strategy we can "streamline" the code path, making the gist of the
method, which is to process payments, obvious. The first of which is to inverts the
`if/else` statement and deal with failure condition early.

Notice the outermost `if !paid` block. This block covers the entirety of the method. This
means that the simple "is this payment paid?" check adds to the rest of the method 1 extra
level of indentation that does not serve a lot of purpose and keeps the "happy path" 1
level away from the method main scanline.

The first and simplest fix to improve the readability, is simply:

#### Instead of

```ruby
def process
  if !paid
    if method == :credit_card
      if !Luhn.check(self.card_number)
        raise 'invalid CC number'
      else
        CreditCard.process(self)
      end
    elsif method == :bitcoin
      if !BTC.check_address(self.wallet_address)
        raise 'invalid BTC wallet address'
      else
        BTC.process(self)
      end
    end
  end
end
```

#### Do this

```ruby
def process
  return if paid

  if method == :credit_card
    if !Luhn.check(self.card_number)
      raise 'invalid CC number'
    else
      CreditCard.process(self)
    end
  elsif method == :bitcoin
    if !BTC.check_address(self.wallet_address)
      raise 'invalid BTC wallet address'
    else
      BTC.process(self)
    end
  end
end
```

## Why?

When reading normal text in a book, we expect lines to line up. Deviating from the norm
sends a signal to the reader that something is different, or off, about the code.

However, by wrapping the entire method in an `if/else` block we make the entire content of
the method reads a little bit harder just for the sake of this one particular condition
check which is not the primary purpose of the method at all.

Inverting the condition so that we can check the `paid` condition and exit early leaves
the rest of the method at 1-indentation, like any other regular method.

This improves readability, for two reasons:

1. It allows reader to "discard" the paid condition from their mind early when reading
   the method. Allowing more cognitive space when debugging.
2. It highlights the gist of the method, which should be about processing the payment, not
   the noises from conditional checks.

## Why Not?

Most of time, we can take this simple technique and re-apply it all the way until we're
left with almost no indentation at all:

```ruby
def process
  return if paid
  raise 'bad CC number'  if method == :credit_card && !Luhn.check(self.card_number)
  raise 'bad BTC wallet' if method == :bitcoin     && !BTC.check_address(self.wallet_address)

  if method == :credit_card
    CreditCard.process(self)
  elsif method == :bitcoin
    BTC.process(self)
  end
end
```

Now it is very obvious that the method is about delegating the procesing of payments to
the right processor class (`CreditCard` for credit cards and `BTC` for bitcoins.)

However, experienced coder will notice that we're also muddying the validation of each
processor as a cost of doing this as well. Processing credit cards now requires scanning
through the `.process` method for the second line (doing the [luhn check][0]) and then
skip to the method check to see that the actual processing is done in another class.

Additionally we have also modified the code flow. The validation checks are now performed
separately from the processing block. If we are not careful during real production code
edits, **we may introduce subtle bugs due to the changed code paths** and other developers
who need to work on this piece of code may not realize that there is a code pattern to be
followed here (validate before processing).

[0]: https://en.wikipedia.org/wiki/Luhn_algorithm

## Split Condition

Alternatively, another strategy we can use to deal with conditional pyramids is to
separate the actual processing out of the conditional branching.

#### Instead of

```ruby
def process
  return if paid

  if method == :credit_card
    if !Luhn.check(self.card_number)
      raise 'invalid CC number'
    else
      CreditCard.process(self)
    end
  elsif method == :bitcoin
    if !BTC.check_address(self.wallet_address)
      raise 'invalid BTC wallet address'
    else
      BTC.process(self)
    end
  end
end
```

#### Do this

```ruby
def process
  return if paid

  if method == :credit_card
    process_credit_card
  elsif method == :bitcoin
    process_bitcoin
  end
end

def process_credit_card
  raise 'invalid CC number' if !Luhn.check(self.card_number)
  CreditCard.process(self)
end

def process_bitcoin
  raise 'invalid BTC wallet address' if !BTC.check_address(self.wallet_address)
  BTC.process(self)
end
```

## Why?

Sometimes complex condition checking cannot be avoided. Or the refactoring cost in terms
of developer time and code complexity may not be worth pursuing. You might also be working
with one of those kinds of engineers that [never writes if-else if they can help it][1].

In this case we can still address the complexity directly by splitting the conditional
"checking" part from the actual "processing" so that the reader can do all the conditional
tree walking to the finish and "unloads" them from their minds before they start looking
at the gist of the actual processing.

Think of this like being a detective. You have to interview several different suspects and
find the true culprit. However, there's an extra problem: the road to each of the
suspect's houses are very snaky and full of potholes.  Imagine you have a clone of
yourself yourself, one of you does the driving while the other think about the case.
This way, it's a lot more likely to figure out the case.

This accomplishes two more things additional to the first two:

1. The "switching" of methods are now clear and obvious. The method do not immediately
   process anything but simply branch to the right processing function.

2. We minimized the distractions of branching when we look at individual processing
   methods (`.process_credit_card` don't talk about bitcoins, `.process_bitcoin` don't
   talk about credit cards.) so that each method's processing code are streamlined and
   more obvious.

Now if another developer is tasked with fixing some issue with credit card processing he
can quickly zero-in onto the actual processing code and see everything related to it in
one place and can quickly tune-out everything else.

[1]: https://medium.com/swlh/stop-using-if-else-statements-f4d2323e6e4

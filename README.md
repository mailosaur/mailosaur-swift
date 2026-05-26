# [Mailosaur - Swift library](https://mailosaur.com/) &middot; [![](https://github.com/mailosaur/mailosaur-swift/workflows/CI/badge.svg)](https://github.com/mailosaur/mailosaur-swift/actions)

Mailosaur lets you automate email and SMS tests as part of software development and QA.

- **Unlimited test email addresses for all**  - every account gives users an unlimited number of test email addresses to test with.
- **End-to-end (e2e) email and SMS testing** Allowing you to set up end-to-end tests for password reset emails, account verification processes and MFA/one-time passcodes sent via text message.
- **Fake SMTP servers** Mailosaur also provides dummy SMTP servers to test with; allowing you to catch email in staging environments - preventing email being sent to customers by mistake.

## Get Started

This guide provides several key sections:

- [Mailosaur - Swift library · ](#mailosaur---swift-library--)
  - [Get Started](#get-started)
    - [Installation](#installation)
    - [Set your API key](#set-your-api-key)
    - [Create your code](#create-your-code)
    - [API Reference](#api-reference)
  - [Creating an account](#creating-an-account)
  - [Test email addresses with Mailosaur](#test-email-addresses-with-mailosaur)
  - [Find an email](#find-an-email)
    - [What is this code doing?](#what-is-this-code-doing)
    - [My email wasn't found](#my-email-wasnt-found)
  - [Find an SMS message](#find-an-sms-message)
  - [Testing plain text content](#testing-plain-text-content)
    - [Extracting verification codes from plain text](#extracting-verification-codes-from-plain-text)
  - [Testing HTML content](#testing-html-content)
    - [Working with HTML using SwiftSoup](#working-with-html-using-swiftsoup)
  - [Working with hyperlinks](#working-with-hyperlinks)
    - [Links in plain text (including SMS messages)](#links-in-plain-text-including-sms-messages)
  - [Working with attachments](#working-with-attachments)
    - [Writing an attachment to disk](#writing-an-attachment-to-disk)
  - [Working with images and web beacons](#working-with-images-and-web-beacons)
    - [Remotely-hosted images](#remotely-hosted-images)
    - [Triggering web beacons](#triggering-web-beacons)
  - [Spam checking](#spam-checking)
  - [Development](#development)
  - [Contacting us](#contacting-us)

You can find the full [Mailosaur documentation](https://mailosaur.com/docs/) on the website.

If you get stuck, just contact us at support@mailosaur.com.

### Installation

Install the Mailosaur Swift library using Swift Package Manager. In Xcode, click `File` -> `Add Packages…`, then enter this repo's URL (`https://github.com/mailosaur/mailosaur-swift`).

Alternatively, add Mailosaur to the `dependencies` in your `Package.swift` file (ensure you use the latest version number):

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/mailosaur/mailosaur-swift", from: "1.x.x")
    ],
    // ...
)
```

You can also install Mailosaur via CocoaPods by adding the following line to your `Podfile`:

```rb
pod 'Mailosaur', '~> 1.1'
```

### Set your API key

Get your API key from the Mailosaur Dashboard and set it as an environment variable:

```sh
export MAILOSAUR_API_KEY='your-api-key-here'
```

### Create your code

Then import the library and create a client:

```swift
import Mailosaur

let mailosaur = try MailosaurClient()
```

### API Reference

This library is powered by the Mailosaur [email & SMS testing API](https://mailosaur.com/docs/api/). You can easily check out the API itself by looking at our [API reference documentation](https://mailosaur.com/docs/api/) or via our Postman or Insomnia collections:

[![Run in Postman](https://run.pstmn.io/button.svg)](https://app.getpostman.com/run-collection/6961255-6cc72dff-f576-451a-9023-b82dec84f95d?action=collection%2Ffork&collection-url=entityId%3D6961255-6cc72dff-f576-451a-9023-b82dec84f95d%26entityType%3Dcollection%26workspaceId%3D386a4af1-4293-4197-8f40-0eb49f831325)
 [![Run in Insomnia](https://insomnia.rest/images/run.svg)](https://insomnia.rest/run/?label=Mailosaur&uri=https%3A%2F%2Fmailosaur.com%2Finsomnia.json)

## Creating an account

Create a [free trial account](https://mailosaur.com/app/signup) for Mailosaur via the website.

Once you have this, navigate to the [API tab](https://mailosaur.com/app/project/api) to find the following values:

- **Server ID** - Servers act like projects, which group your tests together. You need this ID whenever you interact with a server via the API.
- **Server Domain** - Every server has its own domain name. You'll need this to send email to your server.
- **API Key** - You can create an API key per server (recommended), or an account-level API key to use across your whole account. [Learn more about API keys](https://mailosaur.com/docs/managing-your-account/api-keys/).

## Test email addresses with Mailosaur

Mailosaur gives you an **unlimited number of test email addresses** - with no setup or coding required!

Here's how it works:

* When you create an account, you are given a server.
* Every server has its own **Server Domain** name (e.g. `abc123.mailosaur.net`)
* Any email address that ends with `@{YOUR_SERVER_DOMAIN}` will work with Mailosaur without any special setup. For example:
  * `build-423@abc123.mailosaur.net`
  * `john.smith@abc123.mailosaur.net`
  * `rAnDoM63423@abc123.mailosaur.net`
* You can create more servers when you need them. Each one will have its own domain name.

***Can't use test email addresses?** You can also [use SMTP to test email](https://mailosaur.com/docs/email-testing/sending-to-mailosaur/#sending-via-smtp). By connecting your product or website to Mailosaur via SMTP, Mailosaur will catch all email your application sends, regardless of the email address.*

## Find an email

In automated tests you will want to wait for a new email to arrive. This library makes that easy with the `messages.get` method. Here's how you use it:

```swift
import Mailosaur

let mailosaur = try MailosaurClient()

// See https://mailosaur.com/app/project/api
let serverId = "abc123"
let serverDomain = "abc123.mailosaur.net"

let message = try await mailosaur.messages.get(
    server: serverId,
    criteria: MessageSearchCriteria(sentTo: "anything@\(serverDomain)")
)

print(message.subject) // "Hello world!"
```

### What is this code doing?

1. Sets up an instance of `MailosaurClient`, reading the API key from the `MAILOSAUR_API_KEY` environment variable.
2. Waits for an email to arrive at the server with ID `abc123`.
3. Outputs the subject line of the email.

### My email wasn't found

First, check that the email you sent is visible in the [Mailosaur Dashboard](https://mailosaur.com/app/project/messages).

If it is, the likely reason is that by default, `messages.get` only searches emails received by Mailosaur in the last 1 hour. You can override this behavior (see the `receivedAfter` option below), however we only recommend doing this during setup, as your tests will generally run faster with the default settings:

```swift
// Override receivedAfter to search all messages since Jan 1st
let receivedAfter = Calendar.current.date(from: DateComponents(year: 2021, month: 1, day: 1))

let message = try await mailosaur.messages.get(
    server: serverId,
    criteria: MessageSearchCriteria(sentTo: "anything@\(serverDomain)"),
    receivedAfter: receivedAfter
)
```

## Find an SMS message

**Important:** Trial accounts do not automatically have SMS access. Please contact our support team to enable a trial of SMS functionality.

If your account has [SMS testing](https://mailosaur.com/sms-testing/) enabled, you can reserve phone numbers to test with, then use the Mailosaur API in a very similar way to when testing email:

```swift
import Mailosaur

let mailosaur = try MailosaurClient()

let serverId = "abc123"

let sms = try await mailosaur.messages.get(
    server: serverId,
    criteria: MessageSearchCriteria(sentTo: "4471235554444")
)

print(sms.text.body)
```

## Testing plain text content

Most emails, and all SMS messages, should have a plain text body. Mailosaur exposes this content via the `text.body` property on an email or SMS message:

```swift
print(message.text.body) // "Hi Jason, ..."

if let body = message.text.body, body.contains("Jason") {
    print("Email contains \"Jason\"")
}
```

### Extracting verification codes from plain text

You may have an email or SMS message that contains an account verification code, or some other one-time passcode. Mailosaur automatically extracts these for you and makes them available via the `codes` array on the message content:

```swift
print(message.text.body ?? "") // "Your access code is 243546."

print(message.text.codes[0].value) // "243546"
```

[Read more](https://mailosaur.com/docs/automation/codes)

## Testing HTML content

Most emails also have an HTML body, as well as the plain text content. You can access HTML content in a very similar way to plain text:

```swift
print(message.html.body) // "<html><head ..."
```

### Working with HTML using SwiftSoup

If you need to traverse the HTML content of an email — for example, finding an element via a CSS selector — you can use the [SwiftSoup](https://github.com/scinfu/SwiftSoup) library.

Add SwiftSoup to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
```

```swift
import SwiftSoup

// ...

let dom = try SwiftSoup.parse(message.html.body ?? "")

let el = try dom.select(".verification-code")
let verificationCode = try el.text() // "542163"
```

[Read more](https://mailosaur.com/docs/test-cases/html-content/)

## Working with hyperlinks

When an email is sent with an HTML body, Mailosaur automatically extracts any hyperlinks found within anchor (`<a>`) and area (`<area>`) elements and makes these viable via the `html.links` array.

Each link has a text property, representing the display text of the hyperlink within the body, and an href property containing the target URL:

```swift
// How many links?
print(message.html.links.count) // 2

if let firstLink = message.html.links.first {
    print(firstLink.text ?? "") // "Google Search"
    print(firstLink.href) // "https://www.google.com/"
}
```

**Important:** To ensure you always have valid emails, Mailosaur only extracts links that have been correctly marked up with `<a>` or `<area>` tags.

### Links in plain text (including SMS messages)

Mailosaur auto-detects links in plain text content too, which is especially useful for SMS testing:

```swift
// How many links?
print(message.text.links.count) // 2

if let firstLink = message.text.links.first {
    print(firstLink.href) // "https://www.google.com/"
}
```

## Working with attachments

If your email includes attachments, you can access these via the `attachments` property:

```swift
// How many attachments?
print(message.attachments.count) // 2
```

Each attachment contains metadata on the file name and content type:

```swift
if let firstAttachment = message.attachments.first {
    print(firstAttachment.fileName) // "contract.pdf"
    print(firstAttachment.contentType) // "application/pdf"
}
```

The `length` property returns the size of the attached file (in bytes):

```swift
if let firstAttachment = message.attachments.first {
    print(firstAttachment.length ?? 0) // 4028
}
```

### Writing an attachment to disk

```swift
if let firstAttachment = message.attachments.first {
    let fileBytes = try await mailosaur.files.getAttachment(id: firstAttachment.id)

    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileUrl = documentsUrl.appendingPathComponent(firstAttachment.fileName)
    try fileBytes.write(to: fileUrl)
}
```

## Working with images and web beacons

The `html.images` property of a message contains an array of images found within the HTML content of an email. The length of this array corresponds to the number of images found within an email:

```swift
// How many images in the email?
print(message.html.images?.count ?? 0) // 1
```

### Remotely-hosted images

Emails will often contain many images that are hosted elsewhere, such as on your website or product. It is recommended to check that these images are accessible by your recipients.

All images should have an alternative text description, which can be checked using the `alt` attribute.

```swift
if let image = message.html.images?.first {
    print(image.alt) // "Hot air balloon"
}
```

### Triggering web beacons

A web beacon is a small image that can be used to track whether an email has been opened by a recipient.

Because a web beacon is simply another form of remotely-hosted image, you can use the `src` attribute to perform an HTTP request to that address:

```swift
if let image = message.html.images?.first, let url = URL(string: image.src) {
    print(image.src) // "https://example.com/s.png?abc123"

    // Make an HTTP call to trigger the web beacon
    let (_, response) = try await URLSession.shared.data(for: URLRequest(url: url))
    if let res = response as? HTTPURLResponse {
        print(res.statusCode) // 200
    }
}
```

## Spam checking

You can perform a [SpamAssassin](https://spamassassin.apache.org/) check against an email. The structure returned matches the [spam test object](https://mailosaur.com/docs/api/#spam):

```swift
let result = try await mailosaur.analysis.spam(email: message.id)

print(result.score) // 0.5

for rule in result.spamFilterResults.spamAssassin {
    print(rule.rule)
    print(rule.description)
    print(rule.score)
}
```

## Development

If you'd like to contribute to this library, here is how to set it up locally.

The test suite requires the following environment variables to be set:

```sh
export MAILOSAUR_API_KEY=your_api_key
export MAILOSAUR_SERVER=server_id
```

Run all tests:

```sh
swift test
```

## Contacting us

You can get us at [support@mailosaur.com](mailto:support@mailosaur.com)

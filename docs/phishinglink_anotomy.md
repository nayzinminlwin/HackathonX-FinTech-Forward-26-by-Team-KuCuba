# Phishing Link Anatomy & Detection Guide

This guide breaks down the 5 primary URL manipulation tactics used by scammers to deceive users into visiting malicious websites. Use this reference to train teams, build awareness, or audit incoming communications.

---

## 🛑 1. Look-Alike & Typosquatting Domains

Scammers register domains with subtle misspellings of trusted brands, exploiting the fact that readers scan words quickly rather than letter-by-letter.

- **The Trick:** Replacing letters with visually similar numbers, symbols, or missing characters.
- **Examples:**
  - `://mayban.com` _(Missing the "k" in Maybank)_
  - `://amaz0n-support.com` _(Using the number zero instead of the letter "O")_
  - `www.pos-malays1a.cc` _(Using a "1" instead of an "i" and a `.cc` extension)_

## 🛑 2. Deceptive Subdomains

Web addresses are officially resolved from right to left up to the first single slash (`/`). Scammers inject trusted brand names into subdomains on completely unrelated servers they control.

- **The Trick:** The real destination is the domain directly preceding the Top-Level Domain (TLD), but the front of the URL looks legitimate.
- **Examples:**
  - `://shopee.com.secure-login-portal.net` _(The actual site is `secure-login-portal.net`, not Shopee)_
  - `://maybank2u.com.verify-identity.xyz` _(The actual site is `verify-identity.xyz`)_

## 🛑 3. URL Shorteners and Obfuscation

To hide messy, suspicious, or completely unrelated web domains, scammers use public shortening platforms to mask the destination.

- **The Trick:** Forcing the user to click blindly without previewing the final URL destination.
- **Examples:**
  - `bit.ly/MY-parcel-update2026`
  - `://tinyurl.com`
  - `is.gd/shopee-hr-job`

## 🛑 4. Non-Standard Top-Level Domains (TLDs)

Official organizations, utilities, and financial institutions invest in established, high-trust extensions like `.com`, `.com.my`, or `.gov.my`. Scammers bypass this by purchasing cheap, unrestricted generic TLDs.

- **The Trick:** Registering a well-known brand name under an unusual or generic extension.
- **Examples:**
  - `www.pos-malaysia.xyz`
  - `www.kwsp-withdrawal.top`
  - `www.customs-my.biz`

## 🛑 5. Open Redirects

This exploit uses a legitimate, trusted website's infrastructure to forward the target to a malicious external page.

- **The Trick:** The link starts with a highly trusted domain but ends with a query parameter redirecting the traffic elsewhere.
- **Example:** `https://google.com`

---

## 📋 Scam Context Reference Matrix

| Scam Type           | Text Example                                                                                           | URL Tactic Applied                                                    |
| :------------------ | :----------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------- |
| **Banking Panic**   | "MAYBANK: 3 failed login attempts. Change credentials immediately to secure funds."                    | `://mayban.com/newpassword` _(Typosquatting)_                         |
| **Missed Delivery** | "Your parcel cannot be delivered due to incorrect address. Update details within 24 hours."            | `bit.ly/pos-delivery-my` _(Obfuscated Shortener)_                     |
| **Government Fine** | "PDRM: Traffic summons outstanding. Failure to settle via portal will result in vehicle blacklisting." | `www.rmp.gov.my.summons-portal.cc` _(Deceptive Subdomain / Fake TLD)_ |

---

## 🛡️ Quick Verification Rules

1. **Read Right-To-Left:** Look immediately to the left of the first single slash `/` to find the actual host domain.
2. **Never Click Bank Links:** Official banks are legally prohibited from sending active clickable hyperlinks via SMS.
3. **Use Expanders:** Pass shortened links through a URL expander tool before opening them.
4. **Report Suspicious URLs:** Forward fraudulent links to local cyber authorities or the National Scam Response Centre (NSRC).

# Hacker News Reader for iOS

After my favourite reader app stopped working I decided to write my own as every other one I tried had something missing - and it was a good opportunity to take a look at swift.

I experimented using the Firebase API but in the end resorted to writing my own proxy that scrapes the data as the API didn't give access to all the data I wanted in one, lightweight call and the SDK seemed to randomly lock up the app when resuming. This does mean that it doesn't support real time updates but it's something I didn't really use anyway. I may try re-integrating with Firebase for the comments though I haven't made a firm decision yet.

# License

Copyright (c) 2015 Jason Cabot

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

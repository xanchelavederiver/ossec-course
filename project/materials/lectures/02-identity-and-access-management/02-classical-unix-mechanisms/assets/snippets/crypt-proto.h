@@ 44
/* One-way hash the passphrase PHRASE as specified by SETTING, and
   return a string suitable for storage in a Unix-style "passwd" file.

   If SETTING is a previously hashed passphrase, the string returned
   will be equal to SETTING if and only if PHRASE is the same as the
   passphrase that was previously hashed.  See the documentation for
   other ways to use this function.
@@ 57
   If an error occurs (such as SETTING being nonsense or unsupported)
   the string returned will begin with '*', and will not be equal to
   SETTING nor to any valid hashed passphrase.  Otherwise, the string
   will not begin with '*'.  */
extern char *crypt (const char *__phrase, const char *__setting)
__THROW;

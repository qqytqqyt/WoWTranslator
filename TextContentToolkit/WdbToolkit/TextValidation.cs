using System.Globalization;
using System.Text;

namespace WdbToolkit
{
    /// <summary>
    /// Helpers used to decide whether a candidate byte range really is quest text.
    /// </summary>
    public static class TextValidation
    {
        private static readonly UTF8Encoding StrictUtf8 = new UTF8Encoding(false, true);

        /// <summary>
        /// Strictly decodes UTF-8 (rejecting invalid sequences and embedded NULs).
        /// </summary>
        public static bool TryDecodeUtf8(byte[] buffer, int offset, int count, out string value)
        {
            value = null;
            if (offset < 0 || count < 0 || offset + count > buffer.Length)
                return false;

            if (count == 0)
            {
                value = string.Empty;
                return true;
            }

            try
            {
                var decoded = StrictUtf8.GetString(buffer, offset, count);
                if (decoded.IndexOf('\0') >= 0)
                    return false;

                value = decoded;
                return true;
            }
            catch (DecoderFallbackException)
            {
                return false;
            }
        }

        /// <summary>
        /// Whether the string looks like a real quest title: non-empty, no line breaks,
        /// no leading/trailing whitespace, and no illegal/unassigned code points.
        /// </summary>
        public static bool IsPlausibleTitle(string title)
        {
            if (string.IsNullOrEmpty(title))
                return false;

            if (title.IndexOf('\r') >= 0 || title.IndexOf('\n') >= 0)
                return false;

            if (char.IsWhiteSpace(title[0]) || char.IsWhiteSpace(title[title.Length - 1]))
                return false;

            return IsLegalUnicode(title);
        }

        /// <summary>
        /// Rejects unpaired surrogates, unassigned code points and private-use style symbols,
        /// which show up when text is decoded from a misaligned offset.
        /// </summary>
        public static bool IsLegalUnicode(string text)
        {
            for (int i = 0; i < text.Length; i++)
            {
                var category = char.GetUnicodeCategory(text, i);

                if (category == UnicodeCategory.Surrogate ||
                    category == UnicodeCategory.OtherNotAssigned ||
                    category == UnicodeCategory.PrivateUse ||
                    category == UnicodeCategory.Control && text[i] != '\r' && text[i] != '\n' && text[i] != '\t')
                    return false;

                if (char.IsHighSurrogate(text, i))
                    i++;
            }

            return true;
        }
    }
}

using System.Globalization;
using System.Text;

namespace WdbToolkit
{
    /// <summary>
    /// Helpers used to decide whether a candidate byte range really is quest text.
    /// </summary>
    public static class TextValidation
    {
        /// <summary>
        /// Exception-free strict UTF-8 validation (rejects invalid sequences, overlongs,
        /// surrogates, out-of-range code points and embedded NULs). The parser probes vast
        /// numbers of wrong candidate positions, so this must never throw or allocate.
        /// </summary>
        public static bool IsValidUtf8(byte[] buffer, int offset, int count)
        {
            if (offset < 0 || count < 0 || offset + count > buffer.Length)
                return false;

            int i = offset;
            int end = offset + count;
            while (i < end)
            {
                var b = buffer[i];
                if (b < 0x80)
                {
                    if (b == 0)
                        return false;
                    i++;
                    continue;
                }

                int extra;
                if (b >= 0xC2 && b <= 0xDF)
                    extra = 1;
                else if (b >= 0xE0 && b <= 0xEF)
                    extra = 2;
                else if (b >= 0xF0 && b <= 0xF4)
                    extra = 3;
                else
                    return false;

                if (i + extra >= end)
                    return false;

                var b1 = buffer[i + 1];
                if (b1 < 0x80 || b1 > 0xBF)
                    return false;
                if (b == 0xE0 && b1 < 0xA0 ||
                    b == 0xED && b1 > 0x9F ||
                    b == 0xF0 && b1 < 0x90 ||
                    b == 0xF4 && b1 > 0x8F)
                    return false;

                for (int j = 2; j <= extra; j++)
                {
                    var bj = buffer[i + j];
                    if (bj < 0x80 || bj > 0xBF)
                        return false;
                }

                i += extra + 1;
            }

            return true;
        }

        /// <summary>
        /// Strictly decodes UTF-8 (rejecting invalid sequences and embedded NULs).
        /// </summary>
        public static bool TryDecodeUtf8(byte[] buffer, int offset, int count, out string value)
        {
            if (count == 0 && offset >= 0 && offset <= buffer.Length)
            {
                value = string.Empty;
                return true;
            }

            if (!IsValidUtf8(buffer, offset, count))
            {
                value = null;
                return false;
            }

            value = Encoding.UTF8.GetString(buffer, offset, count);
            return true;
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

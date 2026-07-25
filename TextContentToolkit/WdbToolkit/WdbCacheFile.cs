using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace WdbToolkit
{
    /// <summary>
    /// The 24-byte header at the start of every WDB client cache file.
    /// </summary>
    public sealed class WdbCacheHeader
    {
        public const int Size = 24;

        /// <summary>Four character signature, e.g. "WQST" for the quest cache.</summary>
        public string Signature { get; internal set; }

        /// <summary>Client build number the cache was written by, e.g. 68256.</summary>
        public uint ClientBuild { get; internal set; }

        /// <summary>Client locale, e.g. "zhCN".</summary>
        public string Locale { get; internal set; }

        /// <summary>Unknown/version field at offset 0x0C (varies per build).</summary>
        public uint UnknownA { get; internal set; }

        /// <summary>Cache format version field at offset 0x10.</summary>
        public uint CacheVersion { get; internal set; }

        /// <summary>Unknown field at offset 0x14 (usually 0).</summary>
        public uint UnknownB { get; internal set; }

        public override string ToString()
        {
            return string.Format("{0} build={1} locale={2} cacheVersion={3}", Signature, ClientBuild, Locale, CacheVersion);
        }
    }

    /// <summary>
    /// A single raw record of a WDB cache file: an id followed by an opaque payload.
    /// </summary>
    public sealed class WdbCacheRecord
    {
        public WdbCacheRecord(int id, long fileOffset, byte[] payload)
        {
            Id = id;
            FileOffset = fileOffset;
            Payload = payload;
        }

        /// <summary>Entry id (quest id for the quest cache).</summary>
        public int Id { get; }

        /// <summary>Absolute file offset where the record (its id field) starts.</summary>
        public long FileOffset { get; }

        /// <summary>Raw record payload (excludes the id and length fields).</summary>
        public byte[] Payload { get; }
    }

    /// <summary>
    /// Version independent reader for the WDB cache container:
    /// a 24-byte header followed by [id:int32][length:int32][payload] records
    /// and terminated by an id=0/length=0 pair (or end of file).
    /// </summary>
    public sealed class WdbCacheFile
    {
        public string FilePath { get; private set; }

        public WdbCacheHeader Header { get; private set; }

        public IReadOnlyList<WdbCacheRecord> Records { get { return m_records; } }

        /// <summary>Non fatal irregularities encountered while reading the container.</summary>
        public IReadOnlyList<string> Warnings { get { return m_warnings; } }

        public static WdbCacheFile Load(string filePath)
        {
            return Parse(File.ReadAllBytes(filePath), filePath);
        }

        public static WdbCacheFile Parse(byte[] data, string filePath = null)
        {
            if (data == null)
                throw new ArgumentNullException("data");
            if (data.Length < WdbCacheHeader.Size)
                throw new InvalidDataException("File is smaller than the 24-byte WDB header.");

            var file = new WdbCacheFile();
            file.FilePath = filePath;

            var pos = WdbCacheHeader.Size;
            if (LooksLikeHeader(data))
            {
                file.Header = ReadHeader(data);
            }
            else
            {
                // Some hand-copied cache fragments start directly with record data.
                file.Header = new WdbCacheHeader { Signature = "????", Locale = "????" };
                file.m_warnings.Add("No WDB signature found; assuming a headerless record fragment.");
                pos = 0;
            }
            while (pos + 8 <= data.Length)
            {
                var id = BitConverter.ToInt32(data, pos);
                var length = BitConverter.ToInt32(data, pos + 4);

                if (id == 0 && length == 0)
                    break;

                if (length < 0 || pos + 8 + length > data.Length)
                {
                    file.m_warnings.Add(string.Format(
                        "Stopped at file offset {0}: record id={1} declares length {2} which exceeds the remaining {3} bytes.",
                        pos, id, length, data.Length - pos - 8));
                    break;
                }

                var payload = new byte[length];
                Buffer.BlockCopy(data, pos + 8, payload, 0, length);
                file.m_records.Add(new WdbCacheRecord(id, pos, payload));
                pos += 8 + length;
            }

            return file;
        }

        private static bool LooksLikeHeader(byte[] data)
        {
            // Cache signatures are four ASCII letters stored reversed, e.g. "TSQW" => WQST.
            for (int i = 0; i < 4; i++)
            {
                var c = (char)data[i];
                if (c < 'A' || c > 'Z' && c < 'a' || c > 'z')
                    return false;
            }

            return true;
        }

        private static WdbCacheHeader ReadHeader(byte[] data)
        {
            var header = new WdbCacheHeader();
            header.Signature = ReadReversedAscii(data, 0);
            header.ClientBuild = BitConverter.ToUInt32(data, 4);
            header.Locale = ReadReversedAscii(data, 8);
            header.UnknownA = BitConverter.ToUInt32(data, 12);
            header.CacheVersion = BitConverter.ToUInt32(data, 16);
            header.UnknownB = BitConverter.ToUInt32(data, 20);
            return header;
        }

        private static string ReadReversedAscii(byte[] data, int offset)
        {
            var chars = new char[4];
            for (int i = 0; i < 4; i++)
                chars[i] = (char)data[offset + 3 - i];
            return new string(chars).TrimEnd('\0');
        }

        private readonly List<WdbCacheRecord> m_records = new List<WdbCacheRecord>();
        private readonly List<string> m_warnings = new List<string>();
    }
}

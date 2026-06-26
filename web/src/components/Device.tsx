// A minimal titanium phone frame that wraps a real app screenshot. Light,
// editorial, no animation.
export default function Device({
  src,
  alt,
  className = "",
  priority = false,
}: {
  src: string;
  alt: string;
  className?: string;
  priority?: boolean;
}) {
  return (
    <div
      className={`rounded-[2.4rem] border border-paper-300 bg-paper-50 p-2 shadow-[0_24px_60px_-24px_rgba(31,51,41,0.45)] ring-1 ring-black/5 ${className}`}
    >
      <div className="overflow-hidden rounded-[2rem] bg-black">
        <img
          src={src}
          alt={alt}
          loading={priority ? "eager" : "lazy"}
          className="block w-full"
        />
      </div>
    </div>
  );
}

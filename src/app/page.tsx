import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { Features } from "@/components/Features";
import { Stats } from "@/components/Stats";
import { Pricing } from "@/components/Pricing";
import { CTASection } from "@/components/CTASection";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <main className="min-h-screen bg-[var(--background)] selection:bg-blue-100 selection:text-blue-900">
      <Navbar />
      <Hero />
      <Stats />
      <Features />
      <Pricing />
      <CTASection />
      <Footer />
    </main>
  );
}

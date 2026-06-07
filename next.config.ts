import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  webpack: (config, { dev, isServer }) => {
    // Only obfuscate in production builds
    if (!dev && isServer) {
      const WebpackObfuscator = require('webpack-obfuscator');
      config.module.rules.push({
        test: /license-checker\.(ts|js)$/,
        enforce: 'post',
        use: {
          loader: WebpackObfuscator.loader,
          options: {
            compact: true,
            controlFlowFlattening: true,
            controlFlowFlatteningThreshold: 1,
            numbersToExpressions: true,
            simplify: true,
            stringArrayShuffle: true,
            splitStrings: true,
            stringArrayThreshold: 1,
          }
        }
      });
    }
    return config;
  },
};

export default nextConfig;

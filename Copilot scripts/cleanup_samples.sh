#!/bin/bash
# Remove separate sample files since we now have unified SampleSystem.swift
rm -f Sources/Softwaretakt/Models/SimpleSample.swift
rm -f Sources/Softwaretakt/Models/SimpleSampleCategory.swift
rm -f Sources/Softwaretakt/Models/SimpleSampleManager.swift
echo "✅ Cleaned up separate sample files"
